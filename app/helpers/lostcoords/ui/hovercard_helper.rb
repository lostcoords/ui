module Lostcoords::Ui
  module HovercardHelper
    HOVERCARD_SIDES = %i[bottom top].freeze

    # A preview card for what a link points to, such as a profile over a name. It opens after a short
    # hover or on keyboard focus and stays open while the pointer is on it.
    #
    # Yields attributes for the trigger; splat them with `**card` on the link. Pass the card as content:,
    # or src: to load it as HTML from your endpoint the first time it opens, so a long list of triggers
    # costs nothing until one is hovered. The card is a preview: it is hidden from assistive technology
    # and its links are out of the tab order, so everything in it must also be reachable from the page
    # the trigger opens. Inside a paragraph, keep content: to phrasing elements such as spans; HTML that
    # src: loads can hold anything.
    def lc_hovercard(src: nil, content: nil, side: :bottom, **attributes, &block)
      raise ArgumentError, "Pass src: or content:, not both" if src && content
      raise ArgumentError, "Pass src: or content:" unless src || content
      raise ArgumentError, "lc_hovercard needs a block that renders its trigger" unless block
      lc_label!(src, :src) if src
      side = lc_option!(:side, side, HOVERCARD_SIDES)
      trigger = capture({ data: { lc_hovercard_target: "trigger" } }, &block)
      body = content || tag.span(class: "flex flex-col gap-related", data: { slot: "hovercard-loading" }) do
        safe_join([ lc_skeleton(class: "h-10 w-10 rounded-full"), lc_skeleton, lc_skeleton(class: "h-4 w-2/3") ])
      end
      data = { slot: "hovercard", side: side, controller: "lc-hovercard", lc_hovercard_src_value: src,
        action: "mouseenter->lc-hovercard#enter focusin->lc-hovercard#enter mouseleave->lc-hovercard#leave focusout->lc-hovercard#leave" }.compact
      tag.span(**lc_attributes({ class: "lc-hovercard relative inline-flex min-w-0", data: data }, attributes)) do
        safe_join([ trigger, tag.span(body, class: lc_glass_class(shape: :menu, extra: "lc-hovercard__content lc-squircle"), aria: { hidden: true }, data: { slot: "hovercard-content", lc_hovercard_target: "content", loaded: (true unless src) }) ])
      end
    end
  end
end
