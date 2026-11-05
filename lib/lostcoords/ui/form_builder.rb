module Lostcoords::Ui
  # Rails wraps a field with errors in <div class="field_with_errors">. Controls this builder renders show
  # errors themselves, so the wrapper is skipped while it renders; other forms keep Rails' behaviour.
  module SkipsFieldErrorWrapper
    def error_wrapping(html_tag)
      @template_object.instance_variable_get(:@lc_skip_field_error_wrapper) ? html_tag : super
    end
  end
  ActionView::Helpers::Tags::Base.prepend(SkipsFieldErrorWrapper)

  # Rails form builder that renders the library's controls and connects model errors to them.
  #
  #   <%= lc_form_with model: @project do |form| %>
  #     <%= form.field :name, hint: "Shown to members" %>
  #     <%= form.field :email, as: :email_field %>
  #     <%= form.switch :public %>
  #     <%= form.submit %>
  #   <% end %>
  #
  # Every standard helper keeps its Rails signature. A symbol `size:` (:sm, :md, :lg) picks the control
  # size; an integer still sets the HTML size attribute.
  class FormBuilder < ActionView::Helpers::FormBuilder
    INPUTS = %i[
      text_field email_field password_field telephone_field phone_field url_field search_field number_field
      date_field time_field datetime_field datetime_local_field month_field week_field
    ].freeze

    # Every helper that renders a control, wrapped so Rails' error wrapper stays out of its markup.
    WRAPPED = [ *field_helpers, :select, :collection_select, :grouped_collection_select, :time_zone_select,
      :collection_check_boxes, :collection_radio_buttons, :switch, :choice ].uniq - %i[label fields_for fields hidden_field]

    module WithoutFieldErrorWrapper
      WRAPPED.each do |helper|
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{helper}(...)
            without_field_error_wrapper { super(...) }
          end
        RUBY
      end
    end
    prepend WithoutFieldErrorWrapper

    INPUTS.each do |selector|
      define_method(selector) do |method, options = {}|
        size = control_size!(options)
        super(method, control_options(method, options, "input", @template.lc_input_class(size: size)))
      end
    end

    def text_area(method, options = {})
      super(method, control_options(method, options, "textarea", @template.lc_textarea_class))
    end
    alias textarea text_area

    def select(method, choices = nil, options = {}, html_options = {}, &block)
      size = control_size!(html_options)
      super(method, choices, options, control_options(method, html_options, "select", @template.lc_select_class(size: size)), &block)
    end

    SELECT_OPTIONS = %i[include_blank prompt selected disabled].freeze

    alias_method :rails_check_box, :check_box
    private :rails_check_box

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      super(method, control_options(method, options, "checkbox-input", @template.lc_checkbox_class), checked_value, unchecked_value)
    end
    alias checkbox check_box

    def radio_button(method, tag_value, options = {})
      super(method, tag_value, control_options(method, options, "radio-input", @template.lc_radio_class))
    end

    # A checkbox drawn as a switch, with its label beside it.
    def switch(method, label: nil, hint: nil, checked_value: "1", unchecked_value: "0", **options)
      input = rails_check_box(method, control_options(method, { role: "switch" }.merge(options), "switch-input", @template.lc_switch_class, described: true), checked_value, unchecked_value)
      choice_label(method, label, hint, "switch", input)
    end

    # A checkbox with its label beside it.
    def choice(method, label: nil, hint: nil, checked_value: "1", unchecked_value: "0", **options)
      input = rails_check_box(method, control_options(method, options, "checkbox-input", @template.lc_checkbox_class, described: true), checked_value, unchecked_value)
      choice_label(method, label, hint, "checkbox", input)
    end

    def label(method, text = nil, options = {}, &block)
      if text.is_a?(Hash)
        options = text
        text = nil
      end
      super(method, text, options.merge(class: @template.lc_field_label_class(extra: options[:class])), &block)
    end

    def submit(value = nil, options = {})
      if value.is_a?(Hash)
        options = value
        value = nil
      end
      variant = options.delete(:variant) || :primary
      size = options.delete(:size) || :md
      data = { slot: "button", variant: variant, size: size }.merge(options.delete(:data) || {})
      super(value, options.merge(class: @template.lc_button_class(variant: variant, size: size, extra: options[:class]), data: data))
    end

    # Label, control, hint and the attribute's errors in one field. `as:` names the control helper;
    # `as: :select` takes `choices:` and Rails' select options such as `include_blank:`. A block renders
    # a custom control and receives its attributes to splat with `**control`.
    def field(method, label: nil, hint: nil, as: :text_field, choices: nil, **options, &block)
      @template.lc_field(label: label || human_name(method), id: field_id(method), hint: hint, error: errors_for(method)) do |control|
        next @template.capture(control, &block) if block

        attributes = @template.send(:lc_attributes, options.except(*SELECT_OPTIONS), control.to_hash.except(:id))
        if as.to_sym == :select
          select(method, choices, options.slice(*SELECT_OPTIONS), attributes)
        else
          public_send(as, method, attributes.merge(options.slice(*SELECT_OPTIONS)))
        end
      end
    end

    private
      def without_field_error_wrapper
        previous = @template.instance_variable_get(:@lc_skip_field_error_wrapper)
        @template.instance_variable_set(:@lc_skip_field_error_wrapper, true)
        yield
      ensure
        @template.instance_variable_set(:@lc_skip_field_error_wrapper, previous)
      end

      def control_size!(options)
        options[:size].is_a?(Symbol) || options[:size].is_a?(String) && options[:size].match?(/\A[a-z]+\z/) ? options.delete(:size).to_sym : :md
      end

      # described: points aria-describedby at the error a choice label renders, as lc_field does for its control.
      def control_options(method, options, slot, classes, described: false)
        options = options.dup
        aria = (options.delete(:aria) || {}).dup
        aria[:invalid] = true if errors_for(method).any? && !aria.key?(:invalid)
        aria[:describedby] = [ aria[:describedby], "#{field_id(method)}-error" ].compact.join(" ") if described && errors_for(method).any?
        data = { slot: slot }.merge(options.delete(:data) || {})
        options.merge(class: @template.lc_tw(classes, options[:class]), aria: aria, data: data)
      end

      def choice_label(method, text, hint, slot, input)
        @template.send(:lc_choice_label, slot, text || human_name(method), hint, input, errors: errors_for(method), error_id: "#{field_id(method)}-error", for: field_id(method))
      end

      def errors_for(method)
        return [] unless object.respond_to?(:errors)

        object.errors.full_messages_for(method)
      end

      def human_name(method)
        object.class.respond_to?(:human_attribute_name) ? object.class.human_attribute_name(method) : method.to_s.humanize
      end
  end
end
