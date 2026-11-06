module Lostcoords::Ui
  module StructuresHelper
    INPUT_TYPES = %i[text search email password tel url number date time datetime-local month week].freeze

    # plain: true drops the fill, border, padding and height, for a control in an lc_list_field row.
    def lc_input(name: nil, value: nil, type: :text, size: :md, plain: false, **attributes)
      type = lc_option!(:type, type, INPUT_TYPES)
      data = { slot: "input", plain: (true if plain) }.compact
      tag.input(**lc_attributes({ type: type, name: name, value: value, class: lc_input_class(size: size, plain: plain), data: data }, attributes))
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
    # size: :sm is the compact field for dense forms, with a caption label closer to its control.
    def lc_field(label:, id:, hint: nil, error: nil, size: :md, **attributes, &block)
      lc_label!(label, :label)
      lc_label!(id, :id)
      errors = Array(error).compact_blank
      descriptions = [ ("#{id}-hint" if hint.present?), ("#{id}-error" if errors.any?) ].compact
      control = { id: id, aria: { describedby: descriptions.presence&.join(" "), invalid: (true if errors.any?) } }
      tag.div(**lc_attributes({ class: lc_field_class(size: size), data: { slot: "field", invalid: (true if errors.any?) } }, attributes)) do
        safe_join([
          tag.label(label, for: id, class: lc_field_label_class(size: size), data: { slot: "field-label" }),
          (capture(Parts::Field.new(self, id, control), &block) if block),
          *lc_field_messages(id, hint, errors)
        ].compact)
      end
    end

    # Names a group of controls that no single label can: toggles, a picker, several inputs. With an id,
    # the fieldset's aria-describedby points at the hint and error, as lc_field does for its control.
    # size: :sm matches lc_field's compact size. The legend's slot follows the fieldset's.
    def lc_fieldset(legend:, id: nil, hint: nil, error: nil, size: :md, **attributes, &block)
      lc_label!(legend, :legend)
      errors = Array(error).compact_blank
      described = [ ("#{id}-hint" if id && hint.present?), ("#{id}-error" if id && errors.any?) ].compact.presence&.join(" ")
      defaults = { id: id, class: lc_field_class(size: size, extra: "m-0 min-w-0 border-0 p-0"), aria: { invalid: (true if errors.any?), describedby: described }, data: { slot: "fieldset", invalid: (true if errors.any?) } }
      fieldset = lc_attributes(defaults, attributes)
      tag.fieldset(**fieldset) do
        safe_join([
          tag.legend(legend, class: lc_field_label_class(size: size, extra: [ "p-0", ("mb-tight" if size.to_s == "sm") ]), data: { slot: "#{fieldset.dig(:data, :slot)}-legend" }),
          (capture(&block) if block),
          *lc_field_messages(id, hint, errors)
        ].compact)
      end
    end

    # One choice from a few options, as a segmented control. The group decides what its items render:
    # name: makes native radios inside labels, which bring their own arrows, form value and reset;
    # as: :nav makes links, the current one marked with aria-current; otherwise radio buttons whose
    # selection lives in the lc-selection controller.
    # variant: :pills lays the items out as wrapping toggle pills, sized by size:, instead of a segmented track.
    def lc_toggle_group(label:, name: nil, value: nil, as: :div, variant: :segmented, size: :md, **attributes, &block)
      lc_label!(label, :label)
      as = lc_option!(:as, as, %i[div nav])
      variant = lc_option!(:variant, variant, %i[segmented pills])
      size = lc_option!(:size, size, ButtonHelper::BUTTON_SIZES.keys)
      raise ArgumentError, "size: sizes pills; a segmented toggle group has one size" if variant == :segmented && size != :md
      raise ArgumentError, "a nav toggle group marks its current link; it takes no name: or value:" if as == :nav && (name || value)

      mode = as == :nav ? :links : (name ? :radios : :buttons)
      content = lc_within_toggle_group({ mode: mode, name: name, value: value&.to_s, variant: variant, size: size }) { capture(&block) if block }

      defaults = { class: (variant == :pills ? lc_inline_class : lc_toggle_group_class), data: { slot: "toggle-group" } }
      case mode
      when :links
        tag.nav(content, **lc_attributes(defaults, attributes, { aria: { label: label } }))
      when :radios
        tag.div(content, **lc_attributes(defaults, attributes, { role: "radiogroup", aria: { label: label } }))
      else
        defaults[:data].merge!(controller: "lc-selection", action: "click->lc-selection#select keydown->lc-selection#navigate", lc_selection_value_value: value)
        tag.div(content, **lc_attributes(defaults, attributes, { role: "radiogroup", aria: { label: label } }))
      end
    end

    # Takes href: and current: in a nav group, value: and checked: in a named group, and value: and
    # selected: in a button group; arguments from another kind of group raise.
    def lc_toggle_group_item(label = nil, value: nil, selected: nil, checked: nil, href: nil, current: nil, input: {}, **attributes, &block)
      group = @_lc_toggle_group || { mode: :buttons, variant: :segmented }
      given = { value: value, selected: selected, checked: checked, href: href, current: current }.compact.keys
      allowed = { links: %i[href current], radios: %i[value checked], buttons: %i[value selected] }.fetch(group[:mode])
      stray = given - allowed
      raise ArgumentError, "#{stray.join(', ')} can't be used on an item of a #{group[:mode]} toggle group" if stray.any?
      raise ArgumentError, "an item of a nav toggle group needs href:" if group[:mode] == :links && !href

      content = block ? capture(&block) : label
      defaults = { class: (group[:variant] == :pills ? lc_toggle_class(size: group[:size]) : lc_toggle_group_item_class), data: { slot: "toggle-group-item" } }
      return lc_toggle_link(content, href, current, defaults, attributes) if group[:mode] == :links

      value ||= label
      raise ArgumentError, "a toggle group item needs a value: or a label" if value.nil?
      if group[:mode] == :radios
        checked = group[:value] == value.to_s if checked.nil?
        return lc_toggle_radio(content, group[:name], value, checked, input, defaults, attributes)
      end

      required = { type: "button", role: "radio", data: { lc_selection_target: "option", value: value } }
      tag.button(content, **lc_attributes(defaults.merge(aria: { checked: selected || false }), attributes, required))
    end

    # A button that flips its own aria-pressed. href: renders a link marked current when active, and
    # name: a label around a radio checked when active. A caller that sets aria-pressed or
    # aria-expanded owns the state, so the toggle drops its own controller.
    def lc_toggle(label = nil, active: false, ghost: false, size: :md, href: nil, name: nil, value: nil, input: {}, **attributes, &block)
      content = block ? capture(&block) : label
      defaults = { class: lc_toggle_class(ghost: ghost, size: size), data: { slot: "toggle" } }
      return lc_toggle_link(content, href, active, defaults, attributes) if href

      if name
        value ||= label
        lc_label!(value, :value)
        return lc_toggle_radio(content, name, value, active, input, defaults, attributes)
      end

      if lc_normalize_attributes(attributes).fetch(:aria, {}).slice(:pressed, :expanded).any?
        raise ArgumentError, "pass active: or aria: { pressed: }, not both" if active
      else
        defaults[:aria] = { pressed: active }
        defaults[:data].merge!(controller: "lc-toggle", action: "click->lc-toggle#toggle")
      end
      tag.button(content, **lc_attributes(defaults, attributes).merge(type: "button"))
    end

    private
      # Items read the enclosing group's mode, so a nested group restores the outer one.
      def lc_within_toggle_group(group)
        previous, @_lc_toggle_group = @_lc_toggle_group, group
        yield
      ensure
        @_lc_toggle_group = previous
      end

      def lc_toggle_link(content, href, current, defaults, attributes)
        raise ArgumentError, "a link can't be disabled; render it as a button instead" if attributes.key?(:disabled) || attributes.key?("disabled")
        link_to(content, href, **lc_attributes(defaults.merge(aria: { current: ("true" if current) }), attributes))
      end

      def lc_toggle_radio(content, name, value, checked, input, defaults, attributes)
        attributes = attributes.dup
        input = input.merge(disabled: attributes.delete(:disabled)) if attributes.key?(:disabled)
        tag.label(**lc_attributes(defaults, attributes)) do
          safe_join([ radio_button_tag(name, value, checked, **lc_attributes({ class: "sr-only" }, input)), content ])
        end
      end
  end
end
