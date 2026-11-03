module Lostcoords::Ui
  module TableHelper
    def lc_table_class(extra: nil)
      lc_tw("lc-table w-full text-start text-sm", extra)
    end

    def lc_table(**attributes, &block)
      tag.table(**lc_attributes({ class: lc_table_class }, attributes), &block)
    end
  end
end
