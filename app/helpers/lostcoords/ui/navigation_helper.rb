module Lostcoords::Ui
  module NavigationHelper
    BREADCRUMB_LINK = "rounded-sm text-muted-foreground no-underline underline-offset-4 hover:text-foreground hover:underline"

    LINK_TONES = {
      inherit: "text-inherit decoration-current/40 hover:decoration-current",
      muted: "text-muted-foreground decoration-current/40 hover:text-foreground hover:decoration-current",
      primary: "text-primary decoration-current/40 hover:decoration-current"
    }.freeze

    NAV_LINK = "flex min-w-0 items-center gap-related rounded-xl lc-squircle no-underline transition-colors duration-(--lc-motion-quick) " \
      "text-muted-foreground hover:text-foreground aria-[current=page]:text-foreground [&_svg]:shrink-0 " \
      "group-data-[indicator]/nav:relative group-data-[indicator]/nav:aria-[current=page]:bg-transparent"

    # Each layout styles the list and its links; the indicator fill follows the links' corners.
    NAV_LAYOUTS = {
      column: {
        list: "m-0 flex list-none flex-col gap-px p-0",
        link: "[&_svg]:size-4.5",
        indicator: "rounded-xl lc-squircle"
      },
      row: {
        list: "m-0 flex min-w-0 list-none flex-wrap items-center gap-tight p-0",
        link: "shrink-0 justify-center [&_svg]:size-4.5",
        indicator: "rounded-xl lc-squircle"
      },
      dock: {
        list: "m-0 grid list-none grid-flow-col auto-cols-fr gap-0.5 rounded-pill p-tight",
        link: "min-h-14 flex-col justify-center gap-0.5 rounded-pill px-0 text-caption font-semibold hover:bg-transparent [&_svg]:size-6",
        indicator: "rounded-pill bg-(--lc-nav-dock-indicator,var(--lc-nav-indicator,var(--accent)))"
      },
      responsive: {
        list: "m-0 list-none p-0 max-sm:grid max-sm:grid-flow-col max-sm:auto-cols-fr max-sm:gap-0.5 max-sm:rounded-pill max-sm:p-tight " \
          "sm:flex sm:min-w-0 sm:flex-wrap sm:items-center sm:gap-tight",
        link: "justify-center max-sm:min-h-14 max-sm:flex-col max-sm:gap-0.5 max-sm:rounded-pill max-sm:px-0 max-sm:text-caption " \
          "max-sm:font-semibold max-sm:hover:bg-transparent max-sm:[&_svg]:size-6 sm:shrink-0 sm:[&_svg]:size-4.5",
        indicator: "max-sm:rounded-pill max-sm:bg-(--lc-nav-dock-indicator,var(--lc-nav-indicator,var(--accent))) sm:rounded-xl lc-squircle"
      }
    }.freeze
    NAV_INDICATOR = "pointer-events-none absolute start-0 top-0 bg-(--lc-nav-indicator,var(--accent)) opacity-0 " \
      "transition-[translate,width,height,opacity] duration-[400ms] ease-(--lc-ease-out-expo) motion-reduce:transition-none " \
      "group-data-[indicator]/nav:opacity-100"

    # An inline text link. Prose inside lc_prose styles its links already.
    def lc_link_class(tone: :inherit, extra: nil)
      tone = lc_option!(:tone, tone, LINK_TONES.keys)
      lc_tw("rounded-sm underline underline-offset-4 decoration-1 transition-colors duration-(--lc-motion-quick)", LINK_TONES.fetch(tone), extra)
    end

    def lc_link(content = nil, url = nil, tone: :inherit, **attributes, &block)
      if block
        url = content
        content = capture(&block)
      end
      raise ArgumentError, "lc_link needs a URL" if url.blank?

      link_to(content, url, **lc_attributes({ class: lc_link_class(tone: tone), data: { slot: "link" } }, attributes))
    end

    # compact: true is the quieter style for an "On this page" list, in the column layout only.
    def lc_nav_link_class(compact: false, layout: :column, extra: nil)
      layout = lc_option!(:layout, layout, NAV_LAYOUTS.keys)
      raise ArgumentError, "compact: true needs layout: :column" if compact && layout != :column

      size = compact ? "py-tight text-small aria-[current=page]:font-medium" : "min-h-control-md px-3 py-1.5 text-label hover:bg-accent aria-[current=page]:bg-accent aria-[current=page]:font-semibold"
      lc_tw(NAV_LINK, size, (NAV_LAYOUTS.dig(layout, :link) unless compact), extra)
    end

    # Yields a builder with link and group parts; links mark the current page with aria-current.
    # layout: :row lays links in a line, :dock stacks each icon above its label in equal cells for a
    # phone's bottom bar, and :responsive is a dock below sm and a row from sm. indicator: true slides
    # one fill to the current link, starting where it was on the previous page.
    def lc_nav_list(label:, compact: false, layout: :column, indicator: false, **attributes, &block)
      lc_label!(label, :label)
      layout = lc_option!(:layout, layout, NAV_LAYOUTS.keys)
      raise ArgumentError, "compact: true needs layout: :column" if compact && layout != :column

      data = { slot: "nav-list", compact: (true if compact), layout: (layout unless layout == :column), controller: ("lc-nav" if indicator) }.compact
      tag.nav(**lc_attributes({ class: ("group/nav relative" if indicator), aria: { label: label }, data: data }, attributes)) do
        safe_join([
          (tag.span(class: lc_tw(NAV_INDICATOR, NAV_LAYOUTS.dig(layout, :indicator)), aria: { hidden: true }, data: { slot: "nav-indicator", lc_nav_target: "indicator" }) if indicator),
          tag.ul(capture(Parts::NavList.new(self, compact, layout, indicator), &block), class: NAV_LAYOUTS.dig(layout, :list))
        ].compact)
      end
    end

    TOC_INDICATOR = "pointer-events-none absolute -start-px top-0 h-0 w-0.5 rounded-pill bg-primary opacity-0 " \
      "transition-[translate,height,opacity] duration-300 ease-(--lc-ease-out-expo) motion-reduce:transition-none"

    # An "On this page" list that marks the section the reader has scrolled to with aria-current="location".
    # Yields a builder: `toc.link "Usage", "#usage"`, with indent: true for a subsection. headings: takes
    # rendered HTML, such as Markdown output, and lists its headings that carry an id, nesting the deeper level.
    def lc_toc(label: lc_t("lostcoords.ui.toc.label"), headings: nil, levels: 2..3, **attributes, &block)
      lc_label!(label, :label)
      raise ArgumentError, "lc_toc takes headings: or a block, not both" if headings && block
      raise ArgumentError, "lc_toc needs headings: or a block" unless headings || block
      levels = Array(levels)
      raise ArgumentError, "levels must be heading levels from 1 to 6" unless levels.any? && levels.all? { |level| (1..6).cover?(level) }

      toc = Parts::Toc.new(self)
      links = if block
        capture(toc, &block)
      else
        found = Nokogiri::HTML5.fragment(headings.to_s).css(levels.map { |level| "h#{level}[id]" }.join(", "))
        safe_join(found.map { |heading| toc.link(heading.text.strip, "##{heading['id']}", indent: heading.name.delete("h").to_i > levels.min) })
      end

      tag.nav(**lc_attributes({ class: "relative", aria: { label: label }, data: { slot: "toc", controller: "lc-toc" } }, attributes)) do
        safe_join([
          tag.span(class: TOC_INDICATOR, aria: { hidden: true }, data: { slot: "toc-indicator", lc_toc_target: "indicator" }),
          tag.ul(links, class: "m-0 flex list-none flex-col border-s border-border p-0")
        ])
      end
    end

    # Previous and next links between pages in a sequence. Each side takes [title, url] or nil.
    # compact: true shows icon buttons, for a page header.
    def lc_pager(previous: nil, next: nil, label: lc_t("lostcoords.ui.pager.label"), compact: false, **attributes)
      pages = { previous: previous, next: binding.local_variable_get(:next) }
      raise ArgumentError, "lc_pager needs a previous or next page" if pages.values.none?

      tag.nav(**lc_attributes({ aria: { label: label }, class: lc_tw("flex items-stretch gap-related", ("justify-between" unless compact)), data: { slot: "pager" } }, attributes)) do
        safe_join(pages.map do |direction, page|
          next tag.span(class: "flex-1", aria: { hidden: true }) if page.nil? && !compact
          next if page.nil?

          title, url = page
          word = lc_t("lostcoords.ui.pager.#{direction}")
          icon = direction == :previous ? "arrow-left" : "arrow-right"
          glyph = lc_icon(icon, variant: :mini, options: { class: "size-4 shrink-0 rtl:rotate-180", "aria-hidden": true })
          if compact
            link_to(glyph, url, class: lc_icon_button_class(size: :sm), aria: { label: "#{word}: #{title}" }, rel: (direction == :previous ? "prev" : "next"), data: { slot: "pager-#{direction}" })
          else
            link_to(url, rel: (direction == :previous ? "prev" : "next"), data: { slot: "pager-#{direction}" },
              class: lc_tw("flex min-w-0 flex-1 basis-0 flex-col gap-tight rounded-2xl lc-squircle bg-card p-content no-underline text-inherit transition-colors hover:bg-accent sm:max-w-80", ("ms-auto items-end text-end" if direction == :next))) do
              safe_join([
                tag.span(safe_join(direction == :previous ? [ glyph, word ] : [ word, glyph ]), class: "inline-flex items-center gap-tight text-caption text-muted-foreground"),
                tag.span(title, class: "max-w-full truncate text-label")
              ], " ")
            end
          end
        end.compact)
      end
    end

    # The first focusable element on a page; it stays hidden until it receives keyboard focus.
    def lc_skip_link(target = "#main", label: lc_t("lostcoords.ui.skip_link.label"), **attributes)
      defaults = { class: "sr-only focus:not-sr-only focus:fixed focus:top-content focus:start-content focus:z-(--lc-z-toast) " \
        "focus:rounded-xl focus:bg-popover focus:px-content focus:py-related focus:text-label focus:text-popover-foreground focus:shadow-(--lc-shadow-lg)",
        data: { slot: "skip-link" } }
      link_to(label, target, **lc_attributes(defaults, attributes))
    end

    # items: [[label, url], …, label]. The last item is the current page.
    def lc_breadcrumb(items, label: lc_t("lostcoords.ui.breadcrumb.label"), **attributes)
      items = Array(items).map { |item| Array(item) }
      raise ArgumentError, "lc_breadcrumb needs at least one item" if items.empty?

      tag.nav(**lc_attributes({ aria: { label: label }, data: { slot: "breadcrumb" } }, attributes)) do
        tag.ol(class: "m-0 flex min-w-0 list-none flex-wrap items-center gap-tight p-0 text-small") do
          safe_join(items.each_with_index.map do |(text, url), index|
            current = index == items.size - 1
            tag.li(class: "inline-flex min-w-0 items-center gap-tight", data: { slot: "breadcrumb-item" }) do
              safe_join([
                (current || url.nil? ? tag.span(text, class: "truncate font-medium text-foreground", aria: { current: ("page" if current) }) : link_to(text, url, class: BREADCRUMB_LINK)),
                (lc_icon("chevron-right", variant: :mini, options: { class: "size-4 shrink-0 text-muted-foreground rtl:rotate-180", "aria-hidden": true }) unless current)
              ].compact)
            end
          end)
        end
      end
    end

    TABS_ORIENTATIONS = {
      horizontal: { root: "flex min-w-0 flex-col gap-content", list: "max-w-full overflow-x-auto lc-scroll-fade-x" },
      vertical: { root: "flex min-w-0 flex-row items-start gap-content", list: "shrink-0 flex-col items-stretch [&>[role=tab]]:justify-start" }
    }.freeze

    # Yields a builder; each `tabs.panel "Label" do … end` adds a tab and its panel.
    # orientation: :vertical stacks the tabs beside the panels and moves them with Arrow Up and Down.
    # activation: :manual moves focus with the arrows and selects with Enter or Space. list: adds attributes to the tab list.
    def lc_tabs(id:, label:, selected: nil, orientation: :horizontal, activation: :automatic, list: {}, **attributes, &block)
      lc_label!(id, :id)
      lc_label!(label, :label)
      orientation = lc_option!(:orientation, orientation, TABS_ORIENTATIONS.keys)
      activation = lc_option!(:activation, activation, %i[automatic manual])
      layout = TABS_ORIENTATIONS.fetch(orientation)
      tabs = Parts::Tabs.new(self)
      capture(tabs, &block) if block
      raise ArgumentError, "lc_tabs needs at least one panel" if tabs.panels.empty?

      selected = (selected || tabs.panels.first.value).to_s
      raise ArgumentError, "selected tab #{selected.inspect} has no panel" unless tabs.panels.any? { |panel| panel.value == selected }

      key = ->(panel) { "#{id}-#{panel.value.gsub(/[^\w-]+/, '-')}" }
      ids = tabs.panels.map(&key)
      raise ArgumentError, "tab values #{tabs.panels.map(&:value).inspect} produce duplicate ids" unless ids.uniq.size == ids.size
      list_attributes = lc_attributes({ class: lc_toggle_group_class(extra: layout[:list]), data: { slot: "tabs-list" } }, list,
        { role: "tablist", aria: { label: label, orientation: (orientation if orientation == :vertical) } })
      tablist = tag.div(**list_attributes) do
        safe_join(tabs.panels.map do |panel|
          active = panel.value == selected
          tag.button(panel.label, type: "button", role: "tab", id: "#{key.(panel)}-tab", tabindex: (active ? 0 : -1),
            aria: { selected: active, controls: "#{key.(panel)}-panel" }, class: lc_toggle_group_item_class,
            data: { slot: "tabs-trigger", value: panel.value, lc_tabs_target: "tab", action: "click->lc-tabs#select keydown->lc-tabs#navigate" })
        end)
      end
      panels = tabs.panels.map do |panel|
        tag.div(panel.content, **lc_attributes({ role: "tabpanel", id: "#{key.(panel)}-panel", tabindex: 0, hidden: (panel.value != selected),
          aria: { labelledby: "#{key.(panel)}-tab" }, class: lc_tw("min-w-0 rounded-lg outline-offset-4", ("flex-1" if orientation == :vertical)), data: { slot: "tabs-panel", lc_tabs_target: "panel" } }, panel.attributes))
      end
      data = { slot: "tabs", controller: "lc-tabs", lc_tabs_activation_value: (activation.to_s if activation == :manual) }.compact
      tag.div(**lc_attributes({ id: id, class: layout[:root], data: data }, attributes)) do
        safe_join([ tablist, *panels ])
      end
    end
  end
end
