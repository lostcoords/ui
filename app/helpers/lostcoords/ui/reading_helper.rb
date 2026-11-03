module Lostcoords::Ui
  module ReadingHelper
    PROSE_BASE =
      "prose ui-prose min-w-0 max-w-(--ui-reading-measure,65ch) " \
      "text-(length:--ui-reading-size,1rem) leading-(--ui-reading-leading,1.75)"

    def prose_class(extra: nil)
      tw(PROSE_BASE, extra)
    end

    def ui_prose(**attributes, &block)
      tag.div(**ui_attributes({ class: prose_class }, attributes), &block)
    end
  end
end
