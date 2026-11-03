module Lostcoords::Ui
  module FeedbackHelper
    SPINNER_BASE =
      "inline-block rounded-full border-current border-t-transparent animate-spin"

    SPINNER_SIZES = {
      sm: "size-4 border-2",
      base: "size-6 border-2",
      lg: "size-8 border-[3px]"
    }.freeze

    SKELETON_BASE = "block rounded-xl bg-paper-2 animate-pulse"

    EMPTY_STATE_BASE =
      "flex flex-col items-center text-center " \
      "py-6 px-4 sm:py-12 sm:px-6"

    def lc_spinner_class(size: :base, extra: nil)
      lc_tw(SPINNER_BASE, SPINNER_SIZES.fetch(size.to_sym, SPINNER_SIZES[:base]), extra)
    end

    def lc_skeleton_class(extra: nil)
      lc_tw(SKELETON_BASE, extra)
    end

    def lc_empty_state_class(extra: nil)
      lc_tw(EMPTY_STATE_BASE, extra)
    end
  end
end
