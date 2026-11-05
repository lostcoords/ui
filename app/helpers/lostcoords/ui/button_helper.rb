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

    def lc_button_class(variant: :primary, size: :md, block: false, extra: nil)
      variant = lc_option!(:variant, variant, BUTTON_VARIANTS.keys)
      size = lc_option!(:size, size, BUTTON_SIZES.keys)
      lc_tw(
        BUTTON_BASE,
        BUTTON_SIZES.fetch(size),
        (lc_glass_class(shape: :bar) if variant == :glass),
        BUTTON_VARIANTS.fetch(variant),
        ("w-full" if block),
        extra
      )
    end

    def lc_icon_button_class(shape: :square, size: :md, extra: nil)
      shape = lc_option!(:shape, shape, ICON_BUTTON_SHAPES.keys)
      size = lc_option!(:size, size, ICON_BUTTON_SIZES.keys)
      lc_tw(
        ICON_BUTTON_BASE,
        ICON_BUTTON_SHAPES.fetch(shape),
        ICON_BUTTON_SIZES.fetch(size),
        extra
      )
    end
  end
end
