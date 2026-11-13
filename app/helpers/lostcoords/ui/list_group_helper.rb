module Lostcoords::Ui
  module ListGroupHelper
    LIST_ROW = "lc-list-row min-w-0 bg-card text-card-foreground first:rounded-t-3xl last:rounded-b-3xl lc-squircle"
    LIST_ITEM = "flex min-h-16 min-w-0 items-center gap-heading px-content py-heading text-start sm:px-inset"
    LIST_ROW_PADDING = "px-content py-heading sm:px-inset"
    LIST_ICON = "grid size-10 shrink-0 place-items-center rounded-full bg-tile [&>svg:not([class*='size-'])]:size-4.5"
    LIST_ROW_TAGS = %i[div li label details a].freeze
    LIST_ROW_HOVER = "transition-colors duration-(--lc-motion-quick) hover:bg-accent"
    # A linked li or div row: the title's link covers the row, the row's own controls sit above it,
    # and the row shows the link's focus ring.
    LIST_ROW_LINKED =
      "relative has-[[data-slot=list-link]:focus-visible]:outline-2 has-[[data-slot=list-link]:focus-visible]:outline-offset-2 " \
      "has-[[data-slot=list-link]:focus-visible]:outline-(--ring,color-mix(in_oklab,var(--primary)_50%,transparent)) " \
      "[&_:is(a[href],button,input,select,textarea,summary,[tabindex]):not([data-slot=list-link])]:relative " \
      "[&_:is(a[href],button,input,select,textarea,summary,[tabindex]):not([data-slot=list-link])]:z-raised"
    LIST_LINK = "text-inherit no-underline focus-visible:outline-none after:absolute after:inset-0 after:rounded-[inherit] after:content-['']"
    LIST_FIELD_TAGS = %i[div fieldset span].freeze
    LIST_FIELD = "@container px-content py-2.5 transition-colors duration-(--lc-motion-quick) has-[[data-plain]:focus]:bg-accent"
    LIST_FIELD_GRID = "grid min-h-9 grid-cols-[1.25rem_minmax(0,1fr)] items-center gap-x-heading gap-y-related @md:grid-cols-[8rem_minmax(0,1fr)]"
    LIST_FIELD_LABEL =
      "flex items-center gap-related text-label font-semibold text-muted-foreground " \
      "[&_svg]:size-5 [&_svg]:shrink-0 @md:[&_svg]:size-4.5"

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
    # content that pads itself, such as an lc_list_item button. href: makes the row a link. On an li
    # or div row, the title is the link and covers the row, so the block can hold buttons and links
    # of its own; a click elsewhere in the row follows the title.
    def lc_list_row(title = nil, subtitle: nil, icon: nil, href: nil, tag: nil, padded: true, **attributes, &block)
      tag = lc_option!(:tag, tag || (href ? :a : :div), LIST_ROW_TAGS)
      titled = href && tag != :a
      raise ArgumentError, "href: needs tag: :a, :li or :div" if titled && !%i[li div].include?(tag)
      raise ArgumentError, "href: on an li or div row links its title, so it needs one" if titled && title.blank?

      link = (titled ? lc_tw(LIST_ROW_HOVER, LIST_ROW_LINKED) : lc_tw("no-underline", LIST_ROW_HOVER)) if href
      defaults = { href: (href unless titled), data: { slot: "list-row" } }
      return lc_list_item(title, subtitle: subtitle, icon: icon, link: (href if titled), tag: tag, **lc_attributes(defaults.merge(class: lc_tw(LIST_ROW, link)), attributes), &block) if title.present?

      classes = lc_tw(LIST_ROW, (LIST_ROW_PADDING if padded), link)
      content_tag(tag, (capture(&block) if block), **lc_attributes(defaults.merge(class: classes), attributes))
    end

    # A form row: a label column, then the block as the control. In a narrow row the label folds to
    # icon: alone and stays the accessible name. id: makes the label a <label> for that control;
    # tag: :fieldset names a group of controls with a legend. surface: false drops the row's panel,
    # for a row drawn inside another element, such as a collapsible's summary (with tag: :span).
    def lc_list_field(label, icon: nil, id: nil, tag: :div, surface: true, **attributes, &block)
      lc_label!(label, :label)
      tag = lc_option!(:tag, tag, LIST_FIELD_TAGS)
      raise ArgumentError, "id: labels one control; a fieldset is named by its legend" if id && tag == :fieldset

      inline = tag == :span ? :span : :div
      text = content_tag(:span, label, class: "@max-md:sr-only", data: { slot: "list-field-text" })
      glyph = (icon.is_a?(ActiveSupport::SafeBuffer) ? icon : lc_icon(icon, options: { "aria-hidden": true })) if icon.present?
      label_classes = lc_tw(LIST_FIELD_LABEL, ("self-start min-h-control-sm" if tag == :fieldset))
      label_tag = if id
        content_tag(:label, safe_join([ glyph, text ].compact), for: id, class: label_classes, data: { slot: "list-field-label" })
      else
        content_tag(:span, safe_join([ glyph, text ].compact), class: label_classes, aria: { hidden: (true if tag == :fieldset) }, data: { slot: "list-field-label" })
      end
      grid = content_tag(inline, safe_join([ label_tag, (capture(&block) if block) ].compact), class: LIST_FIELD_GRID)
      legend = content_tag(:legend, label, class: "sr-only") if tag == :fieldset
      classes = lc_tw((LIST_ROW if surface), LIST_FIELD, ("block" if tag == :span), ("m-0 min-w-0 border-0" if tag == :fieldset))
      content_tag(tag, safe_join([ legend, grid ].compact), **lc_attributes({ class: classes, data: { slot: "list-field" } }, attributes))
    end

    # The row layout without the row's surface, for an element inside a free-form row: a summary, a
    # button that opens an editor. icon: takes an icon name or your own markup, such as a logo.
    # link: links the title to that URL and stretches the link over the nearest positioned ancestor.
    def lc_list_item(title, subtitle: nil, icon: nil, link: nil, tag: :div, **attributes, &block)
      lc_label!(title, :title)
      glyph = icon.is_a?(ActiveSupport::SafeBuffer) ? icon : lc_icon(icon) if icon.present?
      title = link_to(title, link, class: LIST_LINK, data: { slot: "list-link" }) if link
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
