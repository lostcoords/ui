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

    # Fixed corner that holds toasts. Render it once in the layout and append toasts to it, from flash
    # or a Turbo Stream; it shows in the top layer, above dialogs and sticky chrome.
    def lc_toast_region(**attributes, &block)
      defaults = { class: "lc-toast-region", role: "status", aria: { live: "polite" }, data: { slot: "toast-region", controller: "lc-toast-region" } }
      tag.div(**lc_attributes(defaults, attributes)) { capture(&block) if block }
    end
  end
end
