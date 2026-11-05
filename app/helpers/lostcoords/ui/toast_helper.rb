module Lostcoords::Ui
  module ToastHelper
    # Render toasts inside lc_toast_region, the live region that announces them. A destructive toast
    # is also an alert, so it interrupts.
    def lc_toast(message = nil, tone: :success, timeout: 4000, **attributes, &block)
      tone = lc_option!(:tone, tone, FeedbackHelper::ALERT_ICONS.keys)
      raise ArgumentError, "timeout must be a nonnegative integer" unless timeout.is_a?(Integer) && timeout >= 0

      defaults = { class: lc_glass_class(shape: :hud, extra: "flex items-center gap-related px-content py-heading text-label font-semibold transition-opacity data-leaving:opacity-0"), role: ("alert" if tone == :destructive), data: { slot: "toast", tone: tone, controller: "lc-toast", action: "click->lc-toast#dismiss", lc_toast_timeout_value: timeout } }
      tag.div(**lc_attributes(defaults, attributes)) do
        safe_join([ lc_alert_icon(tone: tone), tag.span(block ? capture(&block) : message) ])
      end
    end

    TOAST_PLACEMENTS = %i[bottom_end bottom_center top_end top_center].freeze

    # Fixed edge that holds toasts. Render it once in the layout and append toasts to it, from flash
    # or a Turbo Stream; it shows in the top layer, above dialogs and sticky chrome. mobile_placement:
    # applies below the sm breakpoint. --lc-toast-offset sets the distance from the edges, and
    # --lc-toast-offset-top or --lc-toast-offset-bottom one edge, such as below a sticky header.
    def lc_toast_region(placement: :bottom_end, mobile_placement: nil, **attributes, &block)
      placement = lc_option!(:placement, placement, TOAST_PLACEMENTS)
      mobile_placement = lc_option!(:mobile_placement, mobile_placement, TOAST_PLACEMENTS) if mobile_placement
      data = { slot: "toast-region", controller: "lc-toast-region", placement: placement.to_s.dasherize, mobile_placement: mobile_placement&.to_s&.dasherize }.compact
      defaults = { class: "lc-toast-region", role: "status", aria: { live: "polite" }, data: data }
      tag.div(**lc_attributes(defaults, attributes)) { capture(&block) if block }
    end
  end
end
