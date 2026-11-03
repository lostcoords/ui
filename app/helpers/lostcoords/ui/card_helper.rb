module Lostcoords::Ui
  module CardHelper
    CARD_BASE =
      "squircle bg-paper-2 border border-transparent rounded-3xl"

    CARD_PADDING = {
      default: "p-5",
      dense: "py-4 px-3.5 sm:p-5"
    }.freeze

    HOVER_LIFT =
      "transition-[transform,box-shadow] duration-[180ms] ease-out " \
      "hover:-translate-y-0.5 hover:shadow-(--shadow)"

    CARD_SURFACE_CHROME =
      "squircle bg-(--card-surface-bg,var(--paper-2)) " \
      "[border:var(--card-surface-border,1px_solid_transparent)] " \
      "rounded-(--card-surface-radius,var(--radius-3xl)) " \
      "shadow-(--card-surface-shadow,none) [--field-bg:var(--paper)] " \
      "[--avatar-cutout:var(--card-surface-bg,var(--paper-2))] " \
      "transition-[background,border-color,box-shadow] duration-[180ms] ease-(--ease-out)"

    FORM_CARD_BASE =
      "form-card @container " \
      "#{CARD_SURFACE_CHROME} " \
      "has-[[data-tone=error]]:[border-color:color-mix(in_oklab,var(--berry)_30%,var(--hairline))]"

    FORM_CARD_PADDINGS = {
      default: "p-(--form-card-padding,1.25rem)",
      compact: "p-(--form-card-padding,1rem_14px) sm:p-(--form-card-padding,20px)",
      snug: "p-(--form-card-padding,1rem_14px) sm:p-(--form-card-padding,1rem_20px)",
      empty: "p-(--form-card-padding,2rem_1.25rem)"
    }.freeze

    FORM_CARD_EMPTY_CONTENT = "text-center text-ink-3"

    def lc_card_class(interactive: false, dense: false, extra: nil)
      lc_tw(
        CARD_BASE,
        CARD_PADDING.fetch(dense ? :dense : :default),
        (HOVER_LIFT if interactive),
        ("hover:bg-paper-3" if interactive),
        extra
      )
    end

    def lc_card_surface_class(extra: nil)
      lc_tw(CARD_SURFACE_CHROME, extra)
    end

    def lc_form_card_class(padding: :default, extra: nil)
      lc_tw(
        FORM_CARD_BASE,
        FORM_CARD_PADDINGS.fetch(padding.to_sym, FORM_CARD_PADDINGS[:default]),
        (FORM_CARD_EMPTY_CONTENT if padding.to_sym == :empty),
        extra
      )
    end
  end
end
