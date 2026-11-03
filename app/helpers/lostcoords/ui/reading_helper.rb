module Lostcoords::Ui
  module ReadingHelper
    PROSE_BASE =
      "prose lc-prose min-w-0 max-w-(--lc-reading-measure,65ch) " \
      "text-(length:--lc-reading-size,1rem) leading-(--lc-reading-leading,1.75)"

    def lc_prose_class(extra: nil)
      lc_tw(PROSE_BASE, extra)
    end

    def lc_prose(**attributes, &block)
      tag.div(**lc_attributes({ class: lc_prose_class }, attributes), &block)
    end
  end
end
