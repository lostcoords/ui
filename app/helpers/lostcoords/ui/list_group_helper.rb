module Lostcoords::Ui
  module ListGroupHelper
    LIST_ROW = "lc-list-row min-w-0 bg-card text-card-foreground lc-squircle"
    # The group rounds its first and last shown children, whatever they are: a row, a field, or a
    # collapsible of rows. A hidden row leaves the rounding to its next shown sibling.
    LIST_GROUP =
      "m-0 grid min-w-0 list-none gap-0.5 p-0 " \
      "[&>:not([hidden]):not(:not([hidden])~*)]:rounded-t-3xl [&>:not([hidden]):not(:has(~:not([hidden])))]:rounded-b-3xl"
    LIST_ITEM = "flex min-h-16 min-w-0 items-center gap-heading px-content py-heading text-start sm:px-inset"
    LIST_ROW_PADDING = "px-content py-heading sm:px-inset"
    LIST_ICON = "grid size-10 shrink-0 place-items-center rounded-full bg-tile [&>svg:not([class*='size-'])]:size-4.5"
    LIST_ROW_ELEMENTS = %i[div li label details a].freeze
    LIST_ROW_HOVER = "transition-colors duration-(--lc-motion-quick) hover:bg-accent"
    # A linked li or div row: the title's link covers the row, the row's own controls sit above it,
    # and the row shows the link's focus ring.
    LIST_ROW_LINKED =
      "relative has-[[data-slot=list-link]:focus-visible]:outline-2 has-[[data-slot=list-link]:focus-visible]:outline-offset-2 " \
      "has-[[data-slot=list-link]:focus-visible]:outline-(--ring,color-mix(in_oklab,var(--primary)_50%,transparent)) " \
      "[&_:is(a[href],button,input,select,textarea,summary,[tabindex]):not([data-slot=list-link])]:relative " \
      "[&_:is(a[href],button,input,select,textarea,summary,[tabindex]):not([data-slot=list-link])]:z-raised"
    LIST_LINK = "text-inherit no-underline focus-visible:outline-none after:absolute after:inset-0 after:rounded-[inherit] after:content-['']"
    # A label row around a hidden radio: the checked row fills, bolds and shows a trailing check, as
    # a menuitemradio does. The global focus halo rings the row while its radio has focus.
    LIST_ROW_CHOICE =
      "group/choice flex items-center gap-heading cursor-pointer transition-colors duration-(--lc-motion-quick) " \
      "hover:bg-accent has-checked:bg-primary-soft has-checked:font-semibold has-disabled:cursor-not-allowed has-disabled:opacity-45"
    LIST_ROW_CHOICE_CHECK = "ms-auto size-4 shrink-0 text-primary invisible group-has-checked/choice:visible"
    LIST_FIELD_ELEMENTS = %i[div fieldset span].freeze
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
    def lc_list_group(as: :div, **attributes, &block)
      as = lc_option!(:as, as, %i[div ul])
      content_tag(as, (capture(&block) if block), **lc_attributes({ class: LIST_GROUP, data: { slot: "list-group" } }, attributes))
    end

    # With a title, the row lays out icon:, the title and subtitle, then the block as its trailing
    # content. Without one, the block is the whole row; padded: false drops the row's padding for
    # content that pads itself, such as an lc_list_item button. href: makes the row a link. On an li
    # or div row, the title is the link and covers the row, so the block can hold buttons and links
    # of its own; a click elsewhere in the row follows the title.
    # choice: :radio makes the row one choice of a radio group: a label around a hidden radio named
    # name: with value:, then the title or block, then a check shown while checked:. input: adds
    # attributes to the radio.
    def lc_list_row(title = nil, subtitle: nil, icon: nil, href: nil, as: nil, padded: true, choice: nil, name: nil, value: nil, checked: false, input: {}, **attributes, &block)
      return lc_list_choice_row(title, choice, name, value, checked, input, attributes, &block) if choice
      raise ArgumentError, "name:, value:, checked: and input: belong to a choice: row" if name || value || checked || input.any?

      as = lc_option!(:as, as || (href ? :a : :div), LIST_ROW_ELEMENTS)
      titled = href && as != :a
      raise ArgumentError, "href: needs as: :a, :li or :div" if titled && !%i[li div].include?(as)
      raise ArgumentError, "href: on an li or div row links its title, so it needs one" if titled && title.blank?

      link = (titled ? lc_tw(LIST_ROW_HOVER, LIST_ROW_LINKED) : lc_tw("no-underline", LIST_ROW_HOVER)) if href
      defaults = { href: (href unless titled), data: { slot: "list-row" } }
      return lc_list_item(title, subtitle: subtitle, icon: icon, link: (href if titled), as: as, **lc_attributes(defaults.merge(class: lc_tw(LIST_ROW, link)), attributes), &block) if title.present?

      classes = lc_tw(LIST_ROW, (LIST_ROW_PADDING if padded), link)
      content_tag(as, (capture(&block) if block), **lc_attributes(defaults.merge(class: classes), attributes))
    end

    private def lc_list_choice_row(title, choice, name, value, checked, input, attributes, &block)
      lc_option!(:choice, choice, %i[radio])
      lc_label!(name, :name)
      raise ArgumentError, "a choice row needs value:" if value.nil?
      raise ArgumentError, "a choice row takes a title or a block, not both" if title.present? && block

      attributes = attributes.dup
      input = input.merge(disabled: attributes.delete(:disabled)) if attributes.key?(:disabled)
      content = block ? capture(&block) : content_tag(:span, title, class: "min-w-0", data: { slot: "list-title" })
      content_tag(:label, **lc_attributes({ class: lc_tw(LIST_ROW, LIST_ROW_PADDING, LIST_ROW_CHOICE), data: { slot: "list-row", choice: "radio" } }, attributes)) do
        safe_join([
          radio_button_tag(name, value, checked, **lc_attributes({ class: "sr-only" }, input)),
          content,
          lc_icon("check", variant: :mini, options: { class: LIST_ROW_CHOICE_CHECK, "aria-hidden": true })
        ])
      end
    end

    # A form row: a label column, then the block as the control. In a narrow row the label folds to
    # icon: alone and stays the accessible name. id: makes the label a <label> for that control;
    # as: :fieldset names a group of controls with a legend. surface: false drops the row's panel,
    # for a row drawn inside another element, such as a collapsible's summary (with as: :span).
    def lc_list_field(label, icon: nil, id: nil, as: :div, surface: true, **attributes, &block)
      lc_label!(label, :label)
      as = lc_option!(:as, as, LIST_FIELD_ELEMENTS)
      raise ArgumentError, "id: labels one control; a fieldset is named by its legend" if id && as == :fieldset

      inline = as == :span ? :span : :div
      text = content_tag(:span, label, class: "@max-md:sr-only", data: { slot: "list-field-text" })
      glyph = (icon.is_a?(ActiveSupport::SafeBuffer) ? icon : lc_icon(icon, options: { "aria-hidden": true })) if icon.present?
      label_classes = lc_tw(LIST_FIELD_LABEL, ("self-start min-h-control-sm" if as == :fieldset))
      label_tag = if id
        content_tag(:label, safe_join([ glyph, text ].compact), for: id, class: label_classes, data: { slot: "list-field-label" })
      else
        content_tag(:span, safe_join([ glyph, text ].compact), class: label_classes, aria: { hidden: (true if as == :fieldset) }, data: { slot: "list-field-label" })
      end
      grid = content_tag(inline, safe_join([ label_tag, (capture(&block) if block) ].compact), class: LIST_FIELD_GRID)
      legend = content_tag(:legend, label, class: "sr-only") if as == :fieldset
      classes = lc_tw((LIST_ROW if surface), LIST_FIELD, ("block" if as == :span), ("m-0 min-w-0 border-0" if as == :fieldset))
      content_tag(as, safe_join([ legend, grid ].compact), **lc_attributes({ class: classes, data: { slot: "list-field" } }, attributes))
    end

    # The row layout without the row's surface, for an element inside a free-form row: a summary, a
    # button that opens an editor. icon: takes an icon name or your own markup, such as a logo.
    # link: links the title to that URL and stretches the link over the nearest positioned ancestor.
    def lc_list_item(title, subtitle: nil, icon: nil, link: nil, as: :div, **attributes, &block)
      lc_label!(title, :title)
      glyph = icon.is_a?(ActiveSupport::SafeBuffer) ? icon : lc_icon(icon) if icon.present?
      title = link_to(title, link, class: LIST_LINK, data: { slot: "list-link" }) if link
      content_tag(as, **lc_attributes({ class: LIST_ITEM, data: { slot: "list-item" } }, attributes)) do
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
