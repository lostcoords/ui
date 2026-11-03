module Lostcoords::Ui
  module TailwindHelper
    CONTROL_SIZES = {
      sm: "min-h-11 py-2",
      base: "min-h-12 py-2.5",
      lg: "min-h-14 py-3.5"
    }.freeze

    def tw(*classes)
      @tailwind_merger ||= TailwindMerge::Merger.new
      @tailwind_merger.merge(classes.flatten.compact.join(" "))
    end
  end
end
