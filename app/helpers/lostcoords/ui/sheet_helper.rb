module Lostcoords::Ui
  module SheetHelper
    SHEET_TAGS = %i[div dialog].freeze
    SHEET_DETENTS = [ "fit", "medium large", "large" ].freeze
    SHEET_SURFACES = %i[glass].freeze
    SHEET_HANDLE = "grid min-h-7 w-full flex-none cursor-grab touch-none place-items-center active:cursor-grabbing sm:hidden"

    # A panel that is an iOS sheet on phones, with the lc-sheet controller. tag: :dialog is a modal
    # <dialog> (lc_dialog builds on it). A :div shows while [data-open] or, with popover:, :popover-open;
    # from sm up it keeps your frame, or with anchored: true it is a popover under its trigger, opened by a
    # FloatingPanel inside a positioned ancestor. detents: "fit", "medium large" or "large". handle: true
    # adds a grab strip above the content; without one the sheet draws its grabber over it.
    # A swipe down dispatches lc-sheet:dismiss; unless a listener cancels it, an open popover hides.
    # With tag: :dialog, size: draws lc_dialog's modal frame at that width, for a dialog whose content
    # brings its own header and labels the dialog with aria-label.
    # surface: :glass draws a :div in the translucent menu material, a menu on desktop and a sheet on phones.
    # Yields a builder whose header and footer parts stay pinned while the content scrolls.
    def lc_sheet(tag: :div, anchored: false, detents: "fit", handle: false, size: nil, surface: nil, **attributes, &block)
      tag = lc_option!(:tag, tag, SHEET_TAGS)
      detents = lc_option!(:detents, detents, SHEET_DETENTS.map(&:to_sym)).to_s
      surface = lc_option!(:surface, surface, SHEET_SURFACES) unless surface.nil?
      raise ArgumentError, "anchored: true needs tag: :div" if anchored && tag == :dialog
      raise ArgumentError, "size: needs tag: :dialog" if size && tag != :dialog
      raise ArgumentError, "surface: :glass needs tag: :div" if surface && tag == :dialog

      defaults = { data: { slot: "sheet", controller: "lc-sheet", lc_sheet_detents_value: detents } }
      defaults[:class] = lc_tw("lc-sheet", ("lc-sheet-anchored" if anchored), (lc_glass_class(shape: :picker) if surface == :glass)) unless tag == :dialog
      defaults[:class] = lc_dialog_class(size: size) if size
      strip = self.tag.span(class: SHEET_HANDLE, aria: { hidden: true }, data: { slot: "sheet-handle", lc_sheet_target: "handle" }) if handle
      content = capture(Parts::Sheet.new(self), &block) if block
      content_tag(tag, safe_join([ strip, content ].compact), **lc_attributes(defaults, attributes))
    end
  end
end
