module Lostcoords::Ui
  module StructuresHelper
    INPUT_TYPES = %i[text search email password tel url number date time datetime-local month week].freeze

    def lc_input(name: nil, value: nil, type: :text, size: :md, **attributes)
      type = lc_option!(:type, type, INPUT_TYPES)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      tag.input(**lc_attributes({ type: type, name: name, value: value, class: lc_input_class(size: size), data: { slot: "input" } }, attributes))
    end

    def lc_textarea(content = nil, name: nil, **attributes, &block)
      tag.textarea(block ? capture(&block) : content, **lc_attributes({ name: name, class: lc_textarea_class, data: { slot: "textarea" } }, attributes))
    end

    def lc_select(options = nil, name: nil, selected: nil, size: :md, **attributes, &block)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      content = block ? capture(&block) : options_for_select(options || [], selected)
      tag.select(content, **lc_attributes({ name: name, class: lc_select_class(size: size), data: { slot: "select" } }, attributes))
    end

    # Yields the control's attributes; splat them into the control with `**field`. error: takes a
    # message or a list of messages, such as `record.errors.full_messages_for(:name)`.
    def lc_field(label:, id:, hint: nil, error: nil, **attributes, &block)
      lc_label!(label, :label)
      lc_label!(id, :id)
      errors = Array(error).compact_blank
      descriptions = [ ("#{id}-hint" if hint.present?), ("#{id}-error" if errors.any?) ].compact
      control = { id: id, aria: { describedby: descriptions.presence&.join(" "), invalid: (true if errors.any?) } }
      tag.div(**lc_attributes({ class: lc_field_class, data: { slot: "field", invalid: (true if errors.any?) } }, attributes)) do
        safe_join([
          tag.label(label, for: id, class: lc_field_label_class, data: { slot: "field-label" }),
          (capture(Parts::Field.new(self, id, control), &block) if block),
          *lc_field_messages(id, hint, errors)
        ].compact)
      end
    end

    def lc_toggle_group(label:, name: nil, value: nil, **attributes, &block)
      lc_label!(label, :label)
      defaults = { class: lc_toggle_group_class, role: "group", aria: { label: label }, data: { slot: "toggle-group", controller: "lc-selection", action: "click->lc-selection#select keydown->lc-selection#navigate", lc_selection_value_value: value } }
      tag.div(**lc_attributes(defaults, attributes, { role: "group", aria: { label: label } })) do
        safe_join([ (hidden_field_tag(name, value, data: { lc_selection_target: "input" }) if name), (capture(&block) if block) ].compact)
      end
    end

    def lc_toggle_group_item(label = nil, value: nil, selected: false, **attributes, &block)
      value ||= label
      lc_label!(value, :value)
      defaults = { class: lc_toggle_group_item_class, type: "button", aria: { pressed: selected }, data: { slot: "toggle-group-item", lc_selection_target: "option", value: value } }
      required = { type: "button", data: { lc_selection_target: "option", value: value } }
      tag.button(block ? capture(&block) : label, **lc_attributes(defaults, attributes, required))
    end

    def lc_toggle(label = nil, active: false, ghost: false, size: :md, **attributes, &block)
      raise ArgumentError, "Use lc_button_link_to for navigation" if attributes.key?(:href) || attributes.key?("href")
      defaults = { class: lc_toggle_class(ghost: ghost, size: size), type: "button", aria: { pressed: active }, data: { slot: "toggle", controller: "lc-toggle", action: "click->lc-toggle#toggle" } }
      tag.button(block ? capture(&block) : label, **lc_attributes(defaults, attributes).merge(type: "button"))
    end
  end
end
