module Lostcoords::Ui
  module SheetHelper
    # Makes a <dialog> an iOS sheet on phones (lc-sheet controller), keeping the dialog's own
    # controllers. detents: "fit", "medium large" or "large".
    SHEET_DETENTS = [ "fit", "medium large", "large" ].freeze

    def lc_sheet_data(data = {}, detents: "fit")
      detents = lc_option!(:detents, detents, SHEET_DETENTS.map(&:to_sym)).to_s
      data = data.to_h.symbolize_keys
      data.merge(
        controller: [ data[:controller], "lc-sheet" ].compact.join(" "),
        lc_sheet_detents_value: detents
      )
    end
  end
end
