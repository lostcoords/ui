module Lostcoords::Ui
  module FeedbackHelper
    SPINNER_BASE =
      "inline-block rounded-full border-current border-t-transparent animate-spin"

    SPINNER_SIZES = {
      sm: "size-4 border-2",
      md: "size-6 border-2",
      lg: "size-8 border-[3px]"
    }.freeze

    SKELETON_BASE = "block rounded-xl bg-muted animate-pulse"

    EMPTY_STATE_BASE =
      "flex flex-col items-center gap-content text-center " \
      "py-section px-content"

    ALERT_BASE = "flex items-start gap-related py-heading px-content rounded-2xl lc-squircle bg-muted text-foreground text-label"
    ALERT_ICONS = {
      neutral: [ "information-circle", "text-muted-foreground" ],
      primary: [ "information-circle", "text-primary" ],
      success: [ "check-circle", "text-success" ],
      warning: [ "exclamation-triangle", "text-warning" ],
      destructive: [ "exclamation-circle", "text-destructive" ]
    }.freeze

    def lc_alert_class(extra: nil)
      lc_tw(ALERT_BASE, extra)
    end

    def lc_alert_icon(tone: :destructive)
      tone = lc_option!(:tone, tone, ALERT_ICONS.keys)
      name, color = ALERT_ICONS.fetch(tone)
      lc_icon name, variant: :mini, options: { class: lc_tw("size-5 shrink-0", color), "aria-hidden": "true" }
    end

    def lc_spinner_class(size: :md, extra: nil)
      lc_tw(SPINNER_BASE, SPINNER_SIZES.fetch(lc_option!(:size, size, SPINNER_SIZES.keys)), extra)
    end

    def lc_skeleton_class(extra: nil)
      lc_tw(SKELETON_BASE, extra)
    end

    def lc_empty_state_class(extra: nil)
      lc_tw(EMPTY_STATE_BASE, extra)
    end
  end
end
