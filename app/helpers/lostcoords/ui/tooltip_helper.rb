module Lostcoords::Ui
  module TooltipHelper
    TOOLTIP_SIDES = %i[top bottom].freeze

    # Yields attributes for the trigger; splat them with `**tip` so the trigger is described by the tooltip.
    # The tooltip shows on hover and keyboard focus, and Escape hides it. It is a hint: keep essential information visible.
    def lc_tooltip(text, id:, side: :top, **attributes, &block)
      lc_label!(text, :text)
      lc_label!(id, :id)
      side = lc_option!(:side, side, TOOLTIP_SIDES)
      trigger = capture({ aria: { describedby: id } }, &block) if block
      tag.span(**lc_attributes({ class: "lc-tooltip relative inline-flex", data: { slot: "tooltip", side: side, controller: "lc-tooltip", action: "mouseenter->lc-tooltip#show focusin->lc-tooltip#show mouseleave->lc-tooltip#hide focusout->lc-tooltip#hide" } }, attributes)) do
        safe_join([ trigger, tag.span(text, id: id, role: "tooltip", class: "lc-tooltip__content", data: { slot: "tooltip-content", lc_tooltip_target: "content" }) ].compact)
      end
    end
  end
end
