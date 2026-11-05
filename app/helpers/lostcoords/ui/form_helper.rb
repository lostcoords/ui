module Lostcoords::Ui
  module FormHelper
    TOGGLE_GROUP_BASE =
      "inline-flex items-center gap-1 rounded-2xl bg-track p-1 lc-squircle"

    TOGGLE_GROUP_ITEM_BASE =
      "lc-press inline-flex items-center justify-center gap-1.5 whitespace-nowrap " \
      "h-control-sm rounded-xl border-0 bg-transparent " \
      "px-3 font-sans text-label cursor-pointer no-underline " \
      "text-muted-foreground not-disabled:hover:text-foreground " \
      "aria-selected:bg-background aria-selected:text-foreground " \
      "aria-checked:bg-background aria-checked:text-foreground " \
      "aria-pressed:bg-background aria-pressed:text-foreground " \
      "has-checked:bg-background has-checked:text-foreground " \
      "aria-[current]:not-aria-[current=false]:bg-background aria-[current]:not-aria-[current=false]:text-foreground " \
      "transition-[background-color,color,box-shadow,transform] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "disabled:cursor-not-allowed disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)] " \
      "has-disabled:cursor-not-allowed has-disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)] " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    TOGGLE_GROUP_ITEM_ACTIVE = "bg-background text-foreground hover:text-foreground"

    INPUT_BASE =
      "w-full max-w-full min-w-0 " \
      "px-3 " \
      "font-sans text-base bg-(--lc-field-bg,var(--input)) text-foreground placeholder:text-muted-foreground " \
      "border border-transparent rounded-xl lc-squircle outline-none " \
      "transition-[border-color,box-shadow] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "focus:shadow-[0_0_0_calc(var(--spacing)*0.5)_var(--ring,color-mix(in_oklab,var(--primary)_50%,transparent))] " \
      "aria-invalid:border-destructive aria-invalid:shadow-[0_0_0_3px_color-mix(in_oklab,var(--destructive)_16%,transparent)]"

    FIELD_BASE = "lc-field grid min-w-0 has-aria-invalid:[&>label]:text-destructive"
    FIELD_SIZES = { sm: "gap-tight", md: "gap-related" }.freeze
    # Field labels use the text roles; TypographyHelper loads after this file, so its sizes are read at call time.
    FIELD_LABEL_ROLES = { sm: :caption, md: :label }.freeze

    FIELD_LABEL_BASE =
      "block font-sans font-semibold text-muted-foreground " \
      "transition-colors duration-(--lc-motion-quick) ease-(--lc-ease-out)"

    # form_with with Lostcoords::Ui::FormBuilder, so form.text_field, form.field and form.submit
    # render library controls. card: true makes the form the card, and gap: makes it a stack, so the
    # form needs no wrapper element.
    def lc_form_with(card: false, padding: :md, gap: nil, **options, &block)
      if card || gap
        stack = lc_stack_class(gap: gap || :inset)
        layout = { class: card ? lc_card_class(padding: padding, extra: stack) : stack, data: ({ slot: "card" } if card) }.compact
        options = lc_attributes(layout, options)
      end
      form_with(**options, builder: Lostcoords::Ui::FormBuilder, &block)
    end

    def lc_toggle_group_class(extra: nil)
      lc_tw(TOGGLE_GROUP_BASE, extra)
    end

    def lc_toggle_group_item_class(active: false, extra: nil)
      lc_tw(TOGGLE_GROUP_ITEM_BASE, (TOGGLE_GROUP_ITEM_ACTIVE if active), extra)
    end

    def lc_input_class(size: :md, extra: nil)
      lc_tw(INPUT_BASE, TailwindHelper::CONTROL_SIZES.fetch(lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)), extra)
    end


    def lc_select_class(size: :md, extra: nil)
      lc_tw(lc_input_class(size: size), "lc-select rounded-pill ps-4 pe-10 cursor-pointer hover:bg-(--lc-input-hover)", extra)
    end

    def lc_textarea_class(extra: nil)
      lc_tw(INPUT_BASE, "min-h-28 py-2 resize-y", extra)
    end

    def lc_field_class(size: :md, extra: nil)
      lc_tw(FIELD_BASE, FIELD_SIZES.fetch(lc_option!(:size, size, FIELD_SIZES.keys)), extra)
    end

    def lc_field_label_class(size: :md, extra: nil)
      role = FIELD_LABEL_ROLES.fetch(lc_option!(:size, size, FIELD_LABEL_ROLES.keys))
      lc_tw(FIELD_LABEL_BASE, TypographyHelper::TEXT_SIZES.fetch(role), extra)
    end
  end
end
