module Lostcoords::Ui
  module TailwindHelper
    # Buttons, inputs, selects, toggles and icon buttons share these heights.
    CONTROL_SIZES = {
      sm: "h-control-sm",
      md: "h-control-md",
      lg: "h-control-lg"
    }.freeze

    # The theme's own scales, so class merging knows text-label is a size and gap-related a gap.
    MERGE_THEME = {
      "text" => %w[display title heading subheading body small label caption eyebrow],
      "spacing" => %w[tight related heading content inset section gutter control-sm control-md control-lg],
      "container" => %w[page reading form],
      "radius" => %w[pill]
    }.freeze

    def lc_tw(*classes)
      @tailwind_merger ||= TailwindMerge::Merger.new(config: { theme: MERGE_THEME })
      @tailwind_merger.merge(classes.flatten.compact.join(" "))
    end
  end
end
