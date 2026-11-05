module Lostcoords::Ui
  module ListGroupHelper
    LIST_ROW = "lc-list-row min-w-0 bg-card text-card-foreground first:rounded-t-3xl last:rounded-b-3xl lc-squircle"
    LIST_ITEM = "flex min-h-16 min-w-0 items-center gap-heading px-content py-heading text-start sm:px-inset"
    LIST_ROW_PADDING = "px-content py-heading sm:px-inset"
    LIST_ICON = "grid size-10 shrink-0 place-items-center rounded-full bg-tile [&>svg:not([class*='size-'])]:size-4.5"
    LIST_ROW_TAGS = %i[div li label details a].freeze

    # A titled group of list rows: the heading, then the block, then an optional footnote. The block
    # holds lc_list_group and anything that belongs with it, such as the form that wraps the rows.
    def lc_list_section(heading, footnote: nil, level: 2, **attributes, &block)
      lc_label!(heading, :heading)
      raise ArgumentError, "Invalid level: #{level.inspect}. Expected an integer from 1 to 6" unless level.is_a?(Integer) && (1..6).include?(level)

      heading_id = "#{attributes[:id]}-heading" if attributes[:id]
      tag.section(**lc_attributes({ class: "grid min-w-0 gap-related", aria: { labelledby: heading_id }, data: { slot: "list-section" } }, attributes)) do
        safe_join([
          tag.public_send("h#{level}", heading, id: heading_id, class: "m-0 px-content text-label font-semibold text-muted-foreground sm:px-inset", data: { slot: "list-heading" }),
          (capture(&block) if block),
          (tag.p(footnote, class: "m-0 px-content text-small text-muted-foreground sm:px-inset [&_a]:text-foreground [&_a]:underline [&_a]:underline-offset-4", data: { slot: "list-footnote" }) if footnote.present?)
        ].compact)
      end
    end

    # Rows as in iOS settings: each row is its own card-coloured panel, 2px apart, and only the
    # first and last rows round.
    def lc_list_group(tag: :div, **attributes, &block)
      tag = lc_option!(:tag, tag, %i[div ul])
      content_tag(tag, (capture(&block) if block), **lc_attributes({ class: "m-0 grid min-w-0 list-none gap-0.5 p-0", data: { slot: "list-group" } }, attributes))
    end

    # With a title, the row lays out icon:, the title and subtitle, then the block as its trailing
    # content. Without one, the block is the whole row; padded: false drops the row's padding for
    # content that pads itself, such as an lc_list_item button. href: makes the row a link.
    def lc_list_row(title = nil, subtitle: nil, icon: nil, href: nil, tag: nil, padded: true, **attributes, &block)
      tag = lc_option!(:tag, tag || (href ? :a : :div), LIST_ROW_TAGS)
      raise ArgumentError, "href: needs tag: :a" if href && tag != :a

      link = ("no-underline transition-colors duration-(--lc-motion-quick) hover:bg-accent" if href)
      defaults = { href: href, data: { slot: "list-row" } }
      return lc_list_item(title, subtitle: subtitle, icon: icon, tag: tag, **lc_attributes(defaults.merge(class: lc_tw(LIST_ROW, link)), attributes), &block) if title.present?

      classes = lc_tw(LIST_ROW, (LIST_ROW_PADDING if padded), link)
      content_tag(tag, (capture(&block) if block), **lc_attributes(defaults.merge(class: classes), attributes))
    end

    # The row layout without the row's surface, for an element inside a free-form row: a summary, a
    # button that opens an editor. icon: takes an icon name or your own markup, such as a logo.
    def lc_list_item(title, subtitle: nil, icon: nil, tag: :div, **attributes, &block)
      lc_label!(title, :title)
      glyph = icon.is_a?(ActiveSupport::SafeBuffer) ? icon : lc_icon(icon) if icon.present?
      content_tag(tag, **lc_attributes({ class: LIST_ITEM, data: { slot: "list-item" } }, attributes)) do
        text = safe_join([
          content_tag(:span, title, class: "font-semibold", data: { slot: "list-title" }),
          (content_tag(:span, subtitle, class: "text-small text-muted-foreground [overflow-wrap:anywhere]", data: { slot: "list-subtitle" }) if subtitle.present?)
        ].compact)
        safe_join([
          (content_tag(:span, glyph, class: LIST_ICON, aria: { hidden: true }, data: { slot: "list-icon" }) if glyph),
          content_tag(:span, text, class: "grid min-w-0 flex-1 gap-0.5", data: { slot: "list-text" }),
          (capture(&block) if block)
        ].compact)
      end
    end
  end
end
