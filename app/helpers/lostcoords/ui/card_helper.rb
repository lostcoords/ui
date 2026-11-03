module Lostcoords::Ui
  module CardHelper
    # Padding sizes set --lc-inset, so nested content that pads or gaps with inset follows the card.
    CARD_PADDING = {
      none: "p-0",
      md: "p-inset",
      sm: "[--lc-inset:var(--spacing-content)] p-inset"
    }.freeze
    HOVER_LIFT = "transition-[transform,box-shadow] duration-(--lc-motion-control) ease-(--lc-ease-out) hover:-translate-y-0.5 hover:shadow-(--lc-shadow)"

    def lc_card_class(interactive: false, padding: :md, extra: nil)
      padding = lc_option!(:padding, padding, CARD_PADDING.keys)
      lc_tw("lc-card lc-squircle", CARD_PADDING.fetch(padding),
        ("#{HOVER_LIFT} hover:bg-accent" if interactive), extra)
    end
  end
end
