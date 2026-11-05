module Lostcoords::Ui
  module CollapsibleHelper
    def lc_collapsible(title:, open: false, **attributes, &block)
      lc_label!(title, :title)
      defaults = { class: lc_card_class(extra: "lc-collapsible"), open: open, data: { slot: "collapsible", controller: "lc-collapsible", action: "click->lc-collapsible#toggle" } }
      render "lostcoords/ui/components/lc_collapsible", title: title, attributes: lc_attributes(defaults, attributes), content: (capture(&block) if block)
    end
  end
end
