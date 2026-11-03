module Lostcoords::Ui
  module SheetHelper
    SHEET_ROW_BASE =
      "grid grid-cols-[1.25rem_minmax(0,1fr)] @md:grid-cols-[8rem_minmax(0,1fr)] items-center " \
      "gap-x-3 gap-y-2 min-h-14 px-4 py-2.5 bg-paper-2"

    SHEET_ROW_LABEL_BASE =
      "flex items-center gap-2 font-body text-sm font-semibold text-ink-3 " \
      "[&_svg]:size-5 @md:[&_svg]:size-4.5 [&_svg]:shrink-0 @max-md:[&>span]:sr-only"

    SHEET_CHIP_BASE = "max-w-full min-w-0 h-11 min-h-11 py-0 px-3.5 gap-2 text-sm bg-paper border-0 [&.active]:font-semibold"

    SHEET_MEMBER_CHIP = "ps-1.5 [&_.avatar]:shrink-0 [--avatar-size:28px]"

    SHEET_DATETIME_INPUT_BASE =
      "min-h-9 px-2 rounded-xl border-0 bg-transparent font-body text-base text-ink tabular-nums cursor-pointer " \
      "outline-none [field-sizing:content] transition-colors hover:bg-paper focus-visible:bg-paper " \
      "[&::-webkit-calendar-picker-indicator]:hidden"

    SHEET_TEXT_INPUT_BASE =
      "w-full min-w-0 min-h-9 p-0 border-0 bg-transparent font-body text-base text-ink placeholder:text-ink-3 aria-invalid:placeholder:text-berry/70 outline-none"

    # Makes a <dialog> an iOS sheet on phones (sheet_controller), keeping the dialog's own
    # controllers. detents: "fit", "medium large" or "large".
    def sheet_data(data = {}, detents: "fit")
      data.merge(
        controller: [ data[:controller], "sheet" ].compact.join(" "),
        sheet_detents_value: detents
      )
    end

    def sheet_row_class(extra: nil)
      tw(SHEET_ROW_BASE, extra)
    end

    def sheet_row_label_class(extra: nil)
      tw(SHEET_ROW_LABEL_BASE, extra)
    end

    def sheet_chip_class(active: false, member: false, extra: nil)
      pill_class(size: :sm, active: active, extra: tw(SHEET_CHIP_BASE, (SHEET_MEMBER_CHIP if member), extra))
    end

    def sheet_datetime_input_class(extra: nil)
      tw(SHEET_DATETIME_INPUT_BASE, extra)
    end

    def sheet_text_input_class(extra: nil)
      tw(SHEET_TEXT_INPUT_BASE, extra)
    end
  end
end
