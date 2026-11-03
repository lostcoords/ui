module Lostcoords::Ui
  module DialogHelper
    DIALOG_SURFACE =
      "border border-(--glass-edge) rounded-3xl bg-paper text-ink shadow-[var(--glass-rim),var(--shadow-lg)]"

    # Below sm these open as iOS sheets (sheet.css), which paint their own surface.
    SHEET_DIALOG_SURFACE =
      "sm:border sm:border-(--glass-edge) sm:rounded-3xl sm:bg-paper text-ink sm:shadow-[var(--glass-rim),var(--shadow-lg)]"

    ANCHORED = "data-anchored:[inset:var(--dialog-top)_var(--dialog-right)_auto_auto] data-anchored:m-0"

    DIALOGS = {
      modal: "app-dialog #{SHEET_DIALOG_SURFACE} sm:w-[min(92vw,31rem)]",
      context:
        "app-dialog context-dialog #{SHEET_DIALOG_SURFACE} sm:w-[min(22rem,calc(100vw-2rem))] " \
        "sm:max-h-[calc(100dvh-2rem)] sm:origin-(--dialog-origin,center) [--dialog-from:scale(0.96)] #{ANCHORED}"
    }.freeze

    def dialog_class(kind = :modal, extra: nil)
      tw("squircle", dialog_kinds.fetch(kind), extra)
    end

    def dialog_surface_class(extra: nil)
      tw(DIALOG_SURFACE, extra)
    end

    private

    def dialog_kinds
      DIALOGS
    end
  end
end
