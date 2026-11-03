module Lostcoords::Ui
  module ButtonHelper
    BUTTON_BASE =
      "inline-flex items-center justify-center gap-2 rounded-full font-body font-medium " \
      "whitespace-nowrap no-underline cursor-pointer " \
      "transition-[background-color,border-color,color,box-shadow,transform] duration-[180ms] ease-out " \
      "hover:-translate-y-px active:translate-y-px active:shadow-none disabled:opacity-40 disabled:pointer-events-none " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    BUTTON_SIZES = {
      sm: "#{TailwindHelper::CONTROL_SIZES[:sm]} px-4 text-sm",
      base: "#{TailwindHelper::CONTROL_SIZES[:base]} px-5 text-base",
      lg: "#{TailwindHelper::CONTROL_SIZES[:lg]} px-7 text-base",
      nav: "#{TailwindHelper::CONTROL_SIZES[:sm]} px-4 text-base"
    }.freeze

    BUTTON_VARIANTS = {
      default: "border border-transparent bg-paper text-ink active:bg-paper-2",
      accent: "border border-transparent bg-sky text-ink-on-accent hover:bg-sky-deep active:bg-sky-deep",
      secondary: "border border-transparent bg-paper-2 text-ink hover:bg-paper-3 active:bg-paper-3",
      glass: "pill-3d text-ink hover:brightness-[0.98] active:brightness-[0.96]",
      ghost: "border border-transparent bg-transparent text-ink-2 hover:bg-(--ghost-hover-bg,var(--paper-2)) hover:text-ink active:bg-(--ghost-hover-bg,var(--paper-2))",
      danger: "border border-transparent bg-transparent text-berry hover:bg-berry/8 active:bg-berry/8"
    }.freeze

    ICON_BUTTON_BASE =
      "inline-grid place-items-center shrink-0 border-0 bg-transparent " \
      "text-ink-3 cursor-pointer no-underline " \
      "transition-[background-color,color,transform] duration-[140ms] ease-out " \
      "hover:bg-paper-2 hover:text-ink active:scale-[0.94] " \
      "disabled:opacity-40 disabled:pointer-events-none " \
      "[&_svg]:block [&_svg]:shrink-0"

    ICON_BUTTON_SHAPES = {
      square: "rounded-xl",
      circle: "rounded-full"
    }.freeze

    ICON_BUTTON_SIZES = {
      sm: "size-11 [&_svg]:size-4",
      base: "size-12 [&_svg]:size-5",
      lg: "size-14 [&_svg]:size-6"
    }.freeze

    def button_class(variant: :default, size: :base, block: false, extra: nil)
      tw(
        BUTTON_BASE,
        BUTTON_SIZES.fetch(size.to_sym, BUTTON_SIZES[:base]),
        button_variants.fetch(variant.to_sym, button_variants[:default]),
        ("w-full" if block),
        extra
      )
    end

    def icon_button_class(shape: :square, size: :base, extra: nil)
      tw(
        ICON_BUTTON_BASE,
        ICON_BUTTON_SHAPES.fetch(shape.to_sym, ICON_BUTTON_SHAPES[:square]),
        ICON_BUTTON_SIZES.fetch(size.to_sym, ICON_BUTTON_SIZES[:base]),
        extra
      )
    end

    private

    def button_variants
      BUTTON_VARIANTS
    end
  end
end
