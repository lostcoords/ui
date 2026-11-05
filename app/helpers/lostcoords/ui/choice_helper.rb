module Lostcoords::Ui
  module ChoiceHelper
    CHOICE_BASE = "shrink-0 size-4.5 m-0 cursor-pointer accent-primary disabled:cursor-not-allowed disabled:opacity-40"

    # The label row centers the control on the first line of text, so a hint wraps under the label.
    CHOICE_LABEL = "lc-choice inline-flex min-w-0 items-start gap-related text-body text-foreground cursor-pointer has-disabled:cursor-not-allowed has-disabled:opacity-60"

    # card: true draws the whole label as a selectable tile, for plan or theme pickers.
    CHOICE_CARD = "flex w-full rounded-2xl lc-squircle border border-transparent bg-tile p-content " \
      "transition-[background-color,border-color] duration-(--lc-motion-quick) ease-(--lc-ease-out) hover:bg-accent " \
      "has-checked:border-primary has-checked:bg-primary-soft has-focus-visible:outline-2 has-focus-visible:outline-offset-2 " \
      "has-focus-visible:outline-(--ring,color-mix(in_oklab,var(--primary)_50%,transparent))"

    def lc_choice_label_class(card: false, extra: nil)
      lc_tw(CHOICE_LABEL, (CHOICE_CARD if card), extra)
    end

    def lc_checkbox_class(extra: nil)
      lc_tw("lc-checkbox rounded-sm", CHOICE_BASE, extra)
    end

    def lc_radio_class(extra: nil)
      lc_tw("lc-radio rounded-full", CHOICE_BASE, extra)
    end

    def lc_switch_class(extra: nil)
      lc_tw("lc-switch shrink-0 m-0 cursor-pointer disabled:cursor-not-allowed disabled:opacity-40", extra)
    end

    # A native checkbox. unchecked_value: submits a value when unchecked, like Rails' check_box; pass nil to omit it.
    # A block adds content under the label, such as a preview inside a card: true tile. A nil label renders the
    # bare input for a row selector the row labels, which then needs aria: { label: }.
    def lc_checkbox(label, name: nil, value: "1", checked: false, unchecked_value: "0", hint: nil, card: false, **attributes, &block)
      lc_choice("checkbox", label, hint, card, name, unchecked_value, { type: "checkbox", name: name, value: value, checked: checked, class: lc_checkbox_class }, attributes, &block)
    end

    def lc_radio(label, name:, value:, checked: false, hint: nil, card: false, **attributes, &block)
      lc_choice("radio", label, hint, card, name, nil, { type: "radio", name: name, value: value, checked: checked, class: lc_radio_class }, attributes, &block)
    end

    # A checkbox drawn as a switch. It submits with the form, like a checkbox.
    def lc_switch(label, name: nil, value: "1", checked: false, unchecked_value: "0", hint: nil, **attributes)
      lc_choice("switch", label, hint, false, name, unchecked_value, { type: "checkbox", role: "switch", name: name, value: value, checked: checked, class: lc_switch_class }, attributes)
    end

    # lc_fieldset with its checkboxes, radios or switches stacked.
    def lc_choice_group(legend:, **options, &block)
      lc_fieldset(legend: legend, **lc_attributes({ data: { slot: "choice-group" } }, options)) do
        tag.div(class: "flex flex-col gap-related", &block)
      end
    end

    private
      def lc_choice(slot, label, hint, card, name, unchecked_value, defaults, attributes, &block)
        input = lc_attributes(defaults.merge(data: { slot: "#{slot}-input" }), attributes)
        lc_label!(label || input.dig(:aria, :label), :label)
        hidden = hidden_field_tag(name, unchecked_value, id: nil, disabled: input[:disabled]) if name && !unchecked_value.nil?
        control = safe_join([ hidden, tag.input(**input) ].compact)
        label.nil? ? control : lc_choice_label(slot, label, hint, control, card: card, &block)
      end

      # Shared with Lostcoords::Ui::FormBuilder, which renders its own inputs.
      def lc_choice_label(slot, label, hint, input, card: false, errors: [], error_id: nil, **attributes, &block)
        extra = capture(&block) if block
        tag.label(**lc_attributes({ class: lc_choice_label_class(card: card), data: { slot: slot, card: (true if card) } }, attributes)) do
          safe_join([
            tag.span(input, class: "flex h-lh items-center"),
            tag.span(class: "flex min-w-0 flex-1 flex-col gap-tight") do
              safe_join([
                tag.span(label, class: ("text-label" if card)),
                (tag.span(hint, class: "text-small text-muted-foreground") if hint.present?),
                (tag.span(safe_join(errors, tag.br), id: error_id, class: "text-small text-destructive", data: { slot: "field-error" }) if errors.any?),
                (tag.span(extra, class: "flex min-w-0 flex-col pt-tight") if extra.present?)
              ].compact)
            end
          ])
        end
      end
  end
end
