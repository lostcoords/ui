module Lostcoords::Ui
  module SheetHelper
    SHEET_ELEMENTS = %i[div dialog].freeze
    SHEET_DETENTS = [ "fit", "medium large", "large" ].freeze
    SHEET_SURFACES = %i[glass].freeze

    # A panel that is a sheet on phones, with the lc-sheet controller: it spans the screen's width and sits
    # on its bottom edge. as: :dialog is a modal <dialog> (lc_dialog builds on it). A :div shows while
    # [data-open] or, with popover:, :popover-open; from sm up it keeps your frame, or with anchored: true it
    # is a popover under its trigger, opened by a FloatingPanel inside a positioned ancestor.
    # detents: "fit" is a half sheet at its content's height, "large" fills the screen and "medium large"
    # drags between half the screen and all of it.
    # A swipe down dispatches lc-sheet:dismiss; unless a listener cancels it, an open popover hides.
    # With as: :dialog, size: draws lc_dialog's modal frame at that width, for a dialog whose content
    # brings its own header and labels the dialog with aria-label.
    # surface: :glass draws a :div in the translucent menu material, a menu on desktop and a sheet on phones.
    # Yields a builder whose header and footer parts stay pinned while the content scrolls, and whose close
    # part is the ✕ at the header's start.
    def lc_sheet(as: :div, anchored: false, detents: "fit", size: nil, surface: nil, **attributes, &block)
      as = lc_option!(:as, as, SHEET_ELEMENTS)
      detents = lc_option!(:detents, detents, SHEET_DETENTS.map(&:to_sym)).to_s
      surface = lc_option!(:surface, surface, SHEET_SURFACES) unless surface.nil?
      raise ArgumentError, "anchored: true needs as: :div" if anchored && as == :dialog
      raise ArgumentError, "size: needs as: :dialog" if size && as != :dialog
      raise ArgumentError, "surface: :glass needs as: :div" if surface && as == :dialog

      defaults = { data: { slot: "sheet", controller: "lc-sheet", lc_sheet_detents_value: detents } }
      defaults[:class] = lc_tw("lc-sheet", ("lc-sheet-anchored" if anchored), (lc_glass_class(shape: :picker) if surface == :glass)) unless as == :dialog
      defaults[:class] = lc_dialog_class(size: size) if size
      content = capture(Parts::Sheet.new(self), &block) if block
      content_tag(as, content, **lc_attributes(defaults, attributes))
    end
  end
end
