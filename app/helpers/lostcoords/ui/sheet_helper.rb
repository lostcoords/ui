module Lostcoords::Ui
  module SheetHelper
    # Makes a <dialog> an iOS sheet on phones (lc-sheet controller), keeping the dialog's own
    # controllers. detents: "fit", "medium large" or "large".
    def lc_sheet_data(data = {}, detents: "fit")
      data.merge(
        controller: [ data[:controller], "lc-sheet" ].compact.join(" "),
        lc_sheet_detents_value: detents
      )
    end
  end
end
