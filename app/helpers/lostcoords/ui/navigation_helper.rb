module Lostcoords::Ui
  module NavigationHelper
    BREADCRUMB_LINK = "rounded-sm text-muted-foreground no-underline underline-offset-4 hover:text-foreground hover:underline"

    LINK_TONES = {
      inherit: "text-inherit decoration-current/40 hover:decoration-current",
      muted: "text-muted-foreground decoration-current/40 hover:text-foreground hover:decoration-current",
      primary: "text-primary decoration-current/40 hover:decoration-current"
    }.freeze

    NAV_LINK = "flex min-w-0 items-center rounded-xl lc-squircle no-underline transition-colors duration-(--lc-motion-quick) " \
      "text-muted-foreground hover:text-foreground aria-[current=page]:text-foreground"

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

    # compact: true is the quieter style for an "On this page" list.
    def lc_nav_link_class(compact: false, extra: nil)
      size = compact ? "py-tight text-small aria-[current=page]:font-medium" : "min-h-control-md px-3 py-1.5 text-label hover:bg-accent aria-[current=page]:bg-accent aria-[current=page]:font-semibold"
      lc_tw(NAV_LINK, size, extra)
    end

    # Yields a builder with link and group parts; links mark the current page with aria-current.
    def lc_nav_list(label:, compact: false, **attributes, &block)
      lc_label!(label, :label)
      tag.nav(**lc_attributes({ aria: { label: label }, data: { slot: "nav-list", compact: (true if compact) } }, attributes)) do
        tag.ul(capture(Parts::NavList.new(self, compact), &block), class: "m-0 flex list-none flex-col gap-px p-0")
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

    # Yields a builder; each `tabs.panel "Label" do … end` adds a tab and its panel.
    def lc_tabs(id:, label:, selected: nil, **attributes, &block)
      lc_label!(id, :id)
      lc_label!(label, :label)
      tabs = Parts::Tabs.new(self)
      capture(tabs, &block) if block
      raise ArgumentError, "lc_tabs needs at least one panel" if tabs.panels.empty?

      selected = (selected || tabs.panels.first.value).to_s
      raise ArgumentError, "selected tab #{selected.inspect} has no panel" unless tabs.panels.any? { |panel| panel.value == selected }

      key = ->(panel) { "#{id}-#{panel.value.gsub(/[^\w-]+/, '-')}" }
      list = tag.div(role: "tablist", aria: { label: label }, class: lc_toggle_group_class(extra: "max-w-full overflow-x-auto lc-scroll-fade-x"), data: { slot: "tabs-list" }) do
        safe_join(tabs.panels.map do |panel|
          active = panel.value == selected
          tag.button(panel.label, type: "button", role: "tab", id: "#{key.(panel)}-tab", tabindex: (active ? 0 : -1),
            aria: { selected: active, controls: "#{key.(panel)}-panel" }, class: lc_toggle_group_item_class,
            data: { slot: "tabs-trigger", value: panel.value, lc_tabs_target: "tab", action: "click->lc-tabs#select keydown->lc-tabs#navigate" })
        end)
      end
      panels = tabs.panels.map do |panel|
        tag.div(panel.content, **lc_attributes({ role: "tabpanel", id: "#{key.(panel)}-panel", tabindex: 0, hidden: (panel.value != selected),
          aria: { labelledby: "#{key.(panel)}-tab" }, class: "min-w-0 rounded-lg outline-offset-4", data: { slot: "tabs-panel", lc_tabs_target: "panel" } }, panel.attributes))
      end
      tag.div(**lc_attributes({ id: id, class: "flex min-w-0 flex-col gap-content", data: { slot: "tabs", controller: "lc-tabs" } }, attributes)) do
        safe_join([ list, *panels ])
      end
    end
  end
end
