module Lostcoords::Ui
  module CollapsibleHelper
    COLLAPSIBLE_INDICATORS = %i[marker chevron none].freeze

    # Yields a builder; `collapsible.summary do … end` replaces the title with your own markup.
    # card: false drops the card surface. summary_class: styles the summary, such as a button class.
    # indicator: :chevron swaps the native marker for a chevron that turns as it opens; it follows the
    # summary's content, so push it to the end with me-auto on a summary element.
    def lc_collapsible(title: nil, open: false, card: true, summary_class: nil, indicator: :marker, **attributes, &block)
      indicator = lc_option!(:indicator, indicator, COLLAPSIBLE_INDICATORS)
      parts = Parts::Collapsible.new(self)
      content = capture(parts, &block) if block
      summary = parts.summary_content || title
      raise ArgumentError, "lc_collapsible needs a title: or a summary part" if summary.blank?
      summary = tag.span(summary, class: "me-auto") if indicator == :chevron && parts.summary_content.nil?

      summary_classes = lc_tw("cursor-pointer text-label font-semibold",
        ("list-none [&::-webkit-details-marker]:hidden" unless indicator == :marker),
        ("flex min-h-control-md items-center gap-related" if indicator == :chevron), summary_class)
      chevron = lc_icon("chevron-down", variant: :mini, options: { class: "size-4 shrink-0 text-muted-foreground", aria: { hidden: true }, data: { slot: "collapsible-indicator" } }) if indicator == :chevron
      defaults = { class: (card ? lc_card_class(extra: "lc-collapsible") : "lc-collapsible"), open: open, data: { slot: "collapsible", controller: "lc-collapsible", action: "click->lc-collapsible#toggle" } }
      render "lostcoords/ui/components/lc_collapsible",
        summary: safe_join([ summary, chevron ].compact),
        summary_attributes: lc_attributes({ class: summary_classes, data: { slot: "collapsible-summary" } }, parts.summary_attributes),
        attributes: lc_attributes(defaults, attributes), content: content
    end
  end
end
