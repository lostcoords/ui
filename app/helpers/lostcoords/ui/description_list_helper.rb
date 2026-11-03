module Lostcoords::Ui
  module DescriptionListHelper
    # Yields a builder; `list.item "Owner", "Ada"` or `list.item("Owner") { … }` adds a row.
    # Rows stack on phones and sit in two columns from the sm breakpoint.
    def lc_description_list(**attributes, &block)
      defaults = { class: "m-0 min-w-0 divide-y divide-border [&>div:first-child]:pt-0 [&>div:last-child]:pb-0", data: { slot: "description-list" } }
      tag.dl(**lc_attributes(defaults, attributes)) do
        capture(Parts::DescriptionList.new(self), &block) if block
      end
    end
  end
end
