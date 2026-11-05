module Lostcoords::Ui
  module DialogHelper
    # Below sm these open as iOS sheets (sheet.css), which paint their own surface.
    SHEET_DIALOG_SURFACE =
      "sm:border sm:border-(--lc-glass-edge) sm:rounded-3xl sm:bg-popover text-popover-foreground sm:shadow-[var(--lc-glass-rim),var(--lc-shadow-lg)]"

    ANCHORED = "data-anchored:[inset:var(--lc-dialog-top)_var(--lc-dialog-right)_auto_auto] data-anchored:m-0"

    # The desktop width reads --lc-dialog-width, so a caller can widen the dialog or size content to it.
    DIALOG_WIDTH = "sm:w-[min(var(--lc-dialog-width),calc(100vw-2rem))]"

    DIALOGS = {
      modal: "lc-dialog #{SHEET_DIALOG_SURFACE} #{DIALOG_WIDTH} sm:max-h-[calc(100dvh-2rem)]",
      context:
        "lc-dialog lc-dialog-context #{SHEET_DIALOG_SURFACE} #{DIALOG_WIDTH} [--lc-dialog-width:22rem] " \
        "sm:max-h-[calc(100dvh-2rem)] sm:origin-(--lc-dialog-origin,center) [--lc-dialog-from:scale(0.96)] #{ANCHORED}"
    }.freeze

    # Desktop widths; below sm every dialog is a full-width sheet.
    DIALOG_SIZES = {
      sm: "[--lc-dialog-width:24rem]",
      md: "[--lc-dialog-width:32rem]",
      lg: "[--lc-dialog-width:40rem]",
      xl: "[--lc-dialog-width:64rem]"
    }.freeze

    CONFIRM_SHEET_ID = "lc-confirm-sheet"

    # size: :sm, :md, :lg or :xl. A modal defaults to :md; a context dialog keeps its compact width.
    def lc_dialog_class(kind = :modal, size: nil, extra: nil)
      kind = lc_option!(:kind, kind, DIALOGS.keys)
      size = lc_option!(:size, size, DIALOG_SIZES.keys) unless size.nil?
      size ||= :md if kind == :modal
      lc_tw("lc-squircle", DIALOGS.fetch(kind), (DIALOG_SIZES.fetch(size) if size), extra)
    end

    # Yields a builder with actions, footer and close parts.
    # trigger: false renders only the <dialog>, for a controller of your own to open; point close_action at it.
    # title_attributes: and description_attributes: reach the heading and description, for a controller that rewrites them.
    def lc_dialog(id:, title:, description: nil, trigger: lc_t("lostcoords.ui.dialog.trigger"), kind: :modal, size: nil, detents: "fit",
      close_action: "lc-dialog#close", close_label: nil, title_attributes: {}, description_attributes: {}, **attributes, &block)
      lc_label!(id, :id)
      lc_label!(title, :title)
      lc_label!(trigger, :trigger) unless trigger == false
      lc_label!(close_action, :close_action)
      detents = lc_option!(:detents, detents, SheetHelper::SHEET_DETENTS.map(&:to_sym)).to_s
      defaults = { class: lc_dialog_class(kind, size: size), aria: { describedby: ("#{id}-description" if description.present?) }, data: { slot: "dialog" } }
      required = { id: id, aria: { labelledby: "#{id}-title" }, data: ({ lc_dialog_target: "dialog" } if trigger) }.compact
      parts = Parts::Dialog.new(self, id, close_action)
      content = capture(parts, &block) if block
      title_tag = tag.h2(title, **lc_attributes({ class: lc_heading_class(size: :subheading), data: { slot: "dialog-title" } }, title_attributes, { id: "#{id}-title" }))
      description_tag = tag.p(description, **lc_attributes({ class: lc_text_class(size: :small, tone: :muted), data: { slot: "dialog-description" } }, description_attributes, { id: "#{id}-description" })) if description.present?
      render "lostcoords/ui/components/lc_dialog", id: id, title: title_tag, description: description_tag, trigger: trigger, detents: detents,
        close_action: close_action, close_label: close_label || lc_t("lostcoords.ui.dialog.close", title: title),
        attributes: lc_attributes(defaults, attributes, required), actions: parts.header_actions, content: content
    end

    # The sheet Turbo's confirm opens. Render it once in the layout and set
    # Turbo.config.forms.confirm to `confirm` from lostcoords/ui/helpers/confirm.
    def lc_confirm_sheet(**attributes)
      defaults = { class: lc_dialog_class(:context), data: { slot: "confirm-sheet", turbo_permanent: true } }
      required = { id: CONFIRM_SHEET_ID, tabindex: -1, aria: { labelledby: "#{CONFIRM_SHEET_ID}-message", describedby: "#{CONFIRM_SHEET_ID}-description" } }
      render "lostcoords/ui/components/lc_confirm_sheet", id: CONFIRM_SHEET_ID, attributes: lc_attributes(defaults, attributes, required)
    end
  end
end
