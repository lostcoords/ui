module Lostcoords::Ui
  module DialogHelper
    # Below sm these open as iOS sheets (sheet.css), which paint their own surface.
    SHEET_DIALOG_SURFACE =
      "sm:border sm:border-(--lc-glass-edge) sm:rounded-3xl sm:bg-popover text-popover-foreground sm:shadow-[var(--lc-glass-rim),var(--lc-shadow-lg)]"

    ANCHORED = "data-anchored:[inset:var(--lc-dialog-top)_var(--lc-dialog-right)_auto_auto] data-anchored:m-0"

    DIALOGS = {
      modal: "lc-dialog #{SHEET_DIALOG_SURFACE} sm:w-[min(92vw,31rem)]",
      context:
        "lc-dialog lc-dialog-context #{SHEET_DIALOG_SURFACE} sm:w-[min(22rem,calc(100vw-2rem))] " \
        "sm:max-h-[calc(100dvh-2rem)] sm:origin-(--lc-dialog-origin,center) [--lc-dialog-from:scale(0.96)] #{ANCHORED}"
    }.freeze

    def lc_dialog_class(kind = :modal, extra: nil)
      lc_tw("lc-squircle", DIALOGS.fetch(lc_option!(:kind, kind, DIALOGS.keys)), extra)
    end

    # Yields a builder with footer and close parts.
    def lc_dialog(id:, title:, description: nil, trigger: lc_t("lostcoords.ui.dialog.trigger"), kind: :modal, detents: "fit", **attributes, &block)
      lc_label!(id, :id)
      lc_label!(title, :title)
      lc_label!(trigger, :trigger)
      defaults = { class: lc_dialog_class(kind), aria: { describedby: ("#{id}-description" if description.present?) }, data: lc_sheet_data({ slot: "dialog" }, detents: detents) }
      required = { id: id, aria: { labelledby: "#{id}-title" }, data: { lc_dialog_target: "dialog" } }
      render "lostcoords/ui/components/lc_dialog", id: id, title: title, description: description, trigger: trigger,
        attributes: lc_attributes(defaults, attributes, required), content: (capture(Parts::Dialog.new(self, id), &block) if block)
    end
  end
end
