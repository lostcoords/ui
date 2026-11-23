module Lostcoords::Ui
  module FormHelper
    TOGGLE_GROUP_BASE =
      "lc-toggle-group inline-flex items-center gap-1 rounded-2xl bg-track p-1 lc-squircle *:grow"

    TOGGLE_GROUP_ITEM_BASE =
      "lc-toggle-group-item lc-press inline-flex items-center justify-center gap-1.5 whitespace-nowrap " \
      "h-control-sm rounded-(--lc-toggle-item-radius,var(--radius-xl)) lc-squircle border-0 bg-transparent " \
      "px-3 font-sans text-label cursor-pointer no-underline " \
      "text-muted-foreground not-disabled:hover:text-foreground " \
      "aria-selected:bg-background aria-selected:text-foreground " \
      "aria-checked:bg-background aria-checked:text-foreground " \
      "aria-pressed:bg-background aria-pressed:text-foreground " \
      "has-checked:bg-background has-checked:text-foreground " \
      "aria-[current]:not-aria-[current=false]:bg-background aria-[current]:not-aria-[current=false]:text-foreground " \
      "transition-[background-color,color,box-shadow,transform] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "lc-disabled:cursor-not-allowed lc-pending:cursor-progress lc-disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)] " \
      "has-lc-disabled:cursor-not-allowed has-lc-pending:cursor-progress has-lc-disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)] " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    TOGGLE_GROUP_ITEM_ACTIVE = "lc-toggle-group-item-active bg-background text-foreground hover:text-foreground"

    # :stacked puts each item's icon over its label; :adaptive makes the group full width and stacks
    # its items only while the group itself is narrow.
    TOGGLE_GROUP_LAYOUTS = { inline: nil, stacked: nil, adaptive: "@container/lc-toggle flex w-full" }.freeze
    TOGGLE_GROUP_ITEM_LAYOUTS = {
      inline: nil,
      stacked: "flex-col h-auto min-h-control-sm gap-0.5 px-1.5 py-1.5 text-caption whitespace-normal text-center text-balance [&_svg]:size-5",
      adaptive: "@max-sm/lc-toggle:flex-col @max-sm/lc-toggle:h-auto @max-sm/lc-toggle:gap-0.5 @max-sm/lc-toggle:px-1.5 " \
        "@max-sm/lc-toggle:py-1.5 @max-sm/lc-toggle:text-caption @max-sm/lc-toggle:[&_svg]:size-5"
    }.freeze
    # A track wider than its container scrolls sideways, its edges fading while there is more to see.
    TOGGLE_GROUP_SCROLL = "lc-scroll-fade-x max-w-full overflow-x-auto [scrollbar-width:none] *:shrink-0"
    # Pills that scroll sideways in one row instead of wrapping. The 2px inset keeps a pill's focus ring
    # inside the scroller, which clips it otherwise. :narrow scrolls only while the nearest @container is
    # under @md and wraps above it; the fade is inert whenever nothing overflows.
    # Class names are written out whole so Tailwind finds them in this source.
    PILLS_SCROLL = {
      true => "lc-scroll-fade-x motion-safe:scroll-smooth flex-nowrap overflow-x-auto overscroll-x-contain [scrollbar-width:none] " \
        "[&::-webkit-scrollbar]:hidden *:shrink-0 -my-0.5 py-0.5 -mx-0.5 px-0.5",
      narrow: "lc-scroll-fade-x motion-safe:scroll-smooth @max-md:flex-nowrap @max-md:overflow-x-auto @max-md:overscroll-x-contain " \
        "@max-md:[scrollbar-width:none] @max-md:[&::-webkit-scrollbar]:hidden @max-md:*:shrink-0 @max-md:-my-0.5 @max-md:py-0.5 " \
        "@max-md:-mx-0.5 @max-md:px-0.5"
    }.freeze

    INPUT_BASE =
      "w-full max-w-full min-w-0 " \
      "px-3 " \
      "font-sans text-base bg-(--lc-field-bg,var(--input)) text-foreground placeholder:text-muted-foreground " \
      "border border-transparent rounded-xl lc-squircle " \
      "transition-[border-color,box-shadow] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "aria-invalid:border-destructive aria-invalid:shadow-[0_0_0_3px_color-mix(in_oklab,var(--destructive)_16%,transparent)] " \
      "lc-disabled:cursor-not-allowed lc-disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)]"

    # Text and nothing else: for a control inside a row that draws the focus ring itself, such as lc_list_field.
    INPUT_PLAIN =
      "w-full max-w-full min-w-0 min-h-9 p-0 border-0 bg-transparent font-sans text-base text-foreground " \
      "placeholder:text-muted-foreground aria-invalid:placeholder:text-destructive outline-none"

    FIELD_BASE = "lc-field grid min-w-0 has-aria-invalid:[&>label]:text-destructive aria-invalid:[&>legend]:text-destructive"
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

    def lc_toggle_group_class(layout: :inline, scroll: false, extra: nil)
      layout = lc_option!(:layout, layout, TOGGLE_GROUP_LAYOUTS.keys)
      lc_tw(TOGGLE_GROUP_BASE, TOGGLE_GROUP_LAYOUTS.fetch(layout), (TOGGLE_GROUP_SCROLL if scroll), extra)
    end

    def lc_toggle_group_item_class(active: false, layout: :inline, extra: nil)
      layout = lc_option!(:layout, layout, TOGGLE_GROUP_ITEM_LAYOUTS.keys)
      lc_tw(TOGGLE_GROUP_ITEM_BASE, TOGGLE_GROUP_ITEM_LAYOUTS.fetch(layout), (TOGGLE_GROUP_ITEM_ACTIVE if active), extra)
    end

    def lc_input_class(size: :md, plain: false, extra: nil)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      return lc_tw(INPUT_PLAIN, extra) if plain

      lc_tw(INPUT_BASE, TailwindHelper::CONTROL_SIZES.fetch(size), extra)
    end


    def lc_select_class(size: :md, extra: nil)
      lc_tw(lc_input_class(size: size), "lc-select rounded-pill ps-4 pe-10 cursor-pointer enabled:hover:bg-(--lc-input-hover)", extra)
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
