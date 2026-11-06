module Lostcoords::Ui
  module ButtonHelper
    # Disabled controls drop their variant colours for a faint tint and dim ink, so they read as unavailable on any surface.
    BUTTON_DISABLED =
      "disabled:cursor-not-allowed disabled:shadow-none " \
      "disabled:[--lc-button-bg:color-mix(in_oklab,var(--foreground)_10%,transparent)] " \
      "disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)]"

    BUTTON_BASE =
      "inline-flex items-center justify-center gap-related rounded-pill font-sans " \
      "whitespace-nowrap no-underline cursor-pointer " \
      "transition-[background-color,border-color,color,box-shadow,transform,translate,scale,filter] duration-(--lc-motion-control) ease-(--lc-ease-out) " \
      "motion-safe:not-disabled:hover:-translate-y-px motion-safe:not-disabled:active:translate-y-px active:shadow-none #{BUTTON_DISABLED} " \
      "[&_svg]:block [&_svg:not([class*='size-'])]:size-[1.1em] [&_svg]:shrink-0"

    # Height comes from the shared control sizes; an icon trims the padding on its side.
    BUTTON_SIZES = {
      sm: "#{TailwindHelper::CONTROL_SIZES[:sm]} px-3 has-[>[data-icon=inline-start]]:ps-2.5 has-[>[data-icon=inline-end]]:pe-2.5 text-label",
      md: "#{TailwindHelper::CONTROL_SIZES[:md]} px-4 has-[>[data-icon=inline-start]]:ps-3.5 has-[>[data-icon=inline-end]]:pe-3.5 text-label",
      lg: "#{TailwindHelper::CONTROL_SIZES[:lg]} px-5 has-[>[data-icon=inline-start]]:ps-4 has-[>[data-icon=inline-end]]:pe-4 text-body font-medium"
    }.freeze

    BUTTON_HOVER =
      "not-disabled:hover:bg-[color-mix(in_oklab,var(--lc-button-bg,var(--secondary))_94%,var(--lc-button-ink,var(--foreground)))] " \
      "not-disabled:active:bg-[color-mix(in_oklab,var(--lc-button-bg,var(--secondary))_94%,var(--lc-button-ink,var(--foreground)))]"

    BUTTON_VARIANTS = {
      primary: "border border-transparent [--lc-button-bg:var(--primary)] [--lc-button-ink:var(--primary-foreground)] bg-(--lc-button-bg) text-(--lc-button-ink) #{BUTTON_HOVER}",
      secondary: "border border-transparent [--lc-button-bg:var(--secondary)] [--lc-button-ink:var(--secondary-foreground)] bg-(--lc-button-bg) text-(--lc-button-ink) #{BUTTON_HOVER}",
      outline: "border border-border bg-transparent text-(--lc-button-ink,var(--foreground)) #{BUTTON_HOVER}",
      glass: "[--lc-button-bg:var(--_lc-glass-fill)] text-(--lc-button-ink,var(--foreground)) #{BUTTON_HOVER}",
      ghost: "border border-transparent bg-transparent text-muted-foreground not-disabled:hover:text-(--lc-button-ink,var(--foreground)) #{BUTTON_HOVER}",
      destructive: "border border-transparent [--lc-button-bg:color-mix(in_oklab,var(--destructive)_60%,black)] [--lc-button-ink:#fff] bg-(--lc-button-bg) text-(--lc-button-ink) #{BUTTON_HOVER}"
    }.freeze

    BUTTON_DESTRUCTIVE_INK = "text-destructive [--lc-button-ink:var(--destructive)]"
    BUTTON_DESTRUCTIVE_SOFT = "[--lc-button-bg:color-mix(in_oklab,var(--destructive)_12%,var(--background))]"

    # A tone recolours a variant without changing its emphasis, so a destructive action can stay quiet.
    BUTTON_TONES = {
      default: BUTTON_VARIANTS.transform_values { "" },
      destructive: {
        primary: "[--lc-button-bg:color-mix(in_oklab,var(--destructive)_60%,black)] [--lc-button-ink:#fff]",
        secondary: "#{BUTTON_DESTRUCTIVE_INK} #{BUTTON_DESTRUCTIVE_SOFT}",
        outline: "#{BUTTON_DESTRUCTIVE_INK} border-[color-mix(in_oklab,var(--destructive)_32%,var(--border))]",
        glass: BUTTON_DESTRUCTIVE_INK,
        ghost: "#{BUTTON_DESTRUCTIVE_INK} #{BUTTON_DESTRUCTIVE_SOFT}",
        destructive: ""
      }
    }.freeze

    SELECT_TRIGGER_BASE =
      "inline-flex items-center justify-start gap-related min-w-0 max-w-full ps-4 pe-3 " \
      "rounded-pill border border-transparent bg-(--lc-field-bg,var(--input)) " \
      "font-sans text-base text-start text-foreground whitespace-nowrap no-underline cursor-pointer " \
      "transition-[background-color,color] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "not-disabled:hover:bg-(--lc-input-hover) aria-expanded:bg-(--lc-input-hover) " \
      "disabled:cursor-not-allowed disabled:text-[color-mix(in_oklab,var(--foreground)_38%,transparent)] " \
      "[&_svg]:block [&_svg]:shrink-0 " \
      "[&>[data-icon=inline-end]]:ms-auto [&>[data-icon=inline-end]]:size-5 [&>[data-icon=inline-end]]:text-muted-foreground " \
      "motion-safe:[&>[data-icon=inline-end]]:transition-transform motion-safe:[&>[data-icon=inline-end]]:duration-(--lc-motion-quick) " \
      "aria-expanded:[&>[data-icon=inline-end]]:rotate-180"

    SPLIT_BUTTON_BASE = "relative inline-flex max-w-full min-w-0 items-stretch"

    SPLIT_BUTTON_ACTION = "min-w-0 flex-1 rounded-e-none border-e-0"

    # The two halves press as one pill, so neither lifts on its own.
    SPLIT_BUTTON_PART = "motion-safe:not-disabled:hover:translate-y-0 motion-safe:not-disabled:active:translate-y-0"

    SPLIT_BUTTON_TOGGLE =
      "shrink-0 px-0 rounded-s-none aria-expanded:bg-[color-mix(in_oklab,var(--lc-button-bg,var(--secondary))_94%,var(--lc-button-ink,var(--foreground)))] [&_svg]:size-4 " \
      "motion-safe:[&_svg]:transition-transform motion-safe:[&_svg]:duration-(--lc-motion-quick) aria-expanded:[&_svg]:rotate-180"

    SPLIT_BUTTON_TOGGLE_WIDTHS = {
      sm: "w-control-sm",
      md: "w-control-md",
      lg: "w-control-lg"
    }.freeze

    # Outline halves already share a visible edge; filled and transparent halves draw one from their ink.
    SPLIT_BUTTON_DIVIDER = "border-s border-s-[color-mix(in_oklab,currentColor_24%,transparent)]"

    ICON_BUTTON_BASE =
      "lc-press inline-grid place-items-center shrink-0 border-0 bg-transparent " \
      "text-muted-foreground cursor-pointer no-underline " \
      "transition-[background-color,color,transform,scale] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "not-disabled:hover:text-(--lc-button-ink,var(--foreground)) #{BUTTON_HOVER} " \
      "#{BUTTON_DISABLED} " \
      "[&_svg]:block [&_svg]:shrink-0"

    ICON_BUTTON_SHAPES = {
      square: "rounded-xl lc-squircle",
      circle: "rounded-pill"
    }.freeze

    ICON_BUTTON_SIZES = {
      sm: "size-control-sm [&_svg]:size-4",
      md: "size-control-md [&_svg]:size-5",
      lg: "size-control-lg [&_svg]:size-6"
    }.freeze

    # A row action that stays out of the way until it is hovered, focused or open.
    ICON_BUTTON_QUIET =
      "focus-visible:text-foreground aria-expanded:text-foreground " \
      "motion-safe:[&_svg]:transition-transform motion-safe:[&_svg]:duration-(--lc-motion-control) motion-safe:[&_svg]:ease-(--lc-ease-out-expo) " \
      "motion-safe:not-disabled:hover:[&_svg]:scale-125 motion-safe:focus-visible:[&_svg]:scale-125 motion-safe:aria-expanded:[&_svg]:scale-125"

    def lc_button_class(variant: :primary, tone: :default, size: :md, block: false, extra: nil)
      variant = lc_option!(:variant, variant, BUTTON_VARIANTS.keys)
      tone = lc_option!(:tone, tone, BUTTON_TONES.keys)
      size = lc_option!(:size, size, BUTTON_SIZES.keys)
      lc_tw(
        BUTTON_BASE,
        BUTTON_SIZES.fetch(size),
        (lc_glass_class(shape: :bar) if variant == :glass),
        BUTTON_VARIANTS.fetch(variant),
        BUTTON_TONES.fetch(tone).fetch(variant),
        ("w-full" if block),
        extra
      )
    end

    # A button that reads as a select: start-aligned content and a trailing chevron that turns while
    # aria-expanded is true. Use it for buttons that open a menu or picker.
    def lc_select_trigger_class(size: :md, block: false, extra: nil)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      lc_tw(SELECT_TRIGGER_BASE, TailwindHelper::CONTROL_SIZES.fetch(size), ("w-full" if block), extra)
    end

    # The base is already a ghost button, so variant: :ghost adds nothing; tone: recolours any variant.
    def lc_icon_button_class(shape: :square, size: :md, variant: :ghost, tone: :default, extra: nil)
      shape = lc_option!(:shape, shape, ICON_BUTTON_SHAPES.keys)
      size = lc_option!(:size, size, ICON_BUTTON_SIZES.keys)
      variant = lc_option!(:variant, variant, BUTTON_VARIANTS.keys)
      tone = lc_option!(:tone, tone, BUTTON_TONES.keys)
      lc_tw(
        ICON_BUTTON_BASE,
        ICON_BUTTON_SHAPES.fetch(shape),
        ICON_BUTTON_SIZES.fetch(size),
        (lc_glass_class(shape: :bar) if variant == :glass),
        (BUTTON_VARIANTS.fetch(variant) unless variant == :ghost),
        BUTTON_TONES.fetch(tone).fetch(variant),
        extra
      )
    end
  end
end
