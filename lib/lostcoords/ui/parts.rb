module Lostcoords::Ui
  # Builders yielded by compound components, so their parts are scoped and discoverable:
  #
  #   <%= lc_card do |card| %>
  #     <%= card.header title: "Members", description: "People in this workspace" %>
  #     <%= card.content do %>…<% end %>
  #     <%= card.footer do %>…<% end %>
  #   <% end %>
  #
  # Every part carries data-slot, so a context can style it without matching classes.
  module Parts
    class Base
      def initialize(view)
        @view = view
      end

      private
        attr_reader :view

        def merge(defaults, attributes)
          view.send(:lc_attributes, defaults, attributes)
        end

        def slot(name, attributes, defaults = {})
          merge(defaults.merge(data: { slot: name }), attributes)
        end

        def part(tag_name, name, classes, attributes, &block)
          view.content_tag(tag_name, slot(name, attributes, class: classes), &block)
        end
    end

    class Card < Base
      def header(title: nil, description: nil, level: 3, **attributes, &actions)
        heading = [ (self.title(title, level: level) if title), (self.description(description) if description) ].compact
        action = view.capture(&actions) if actions
        part(:header, "card-header", "flex min-w-0 items-start justify-between gap-content", attributes) do
          view.safe_join([
            (view.tag.div(view.safe_join(heading), class: "flex min-w-0 flex-col gap-tight", data: { slot: "card-heading" }) if heading.any?),
            (view.tag.div(action, class: "flex shrink-0 items-center gap-related", data: { slot: "card-action" }) if action.present?)
          ].compact)
        end
      end

      def title(content = nil, level: 3, **attributes, &block)
        view.lc_heading(content, level: level, size: :subheading, **slot("card-title", attributes), &block)
      end

      def description(content = nil, **attributes, &block)
        view.lc_text(content, size: :small, tone: :muted, **slot("card-description", attributes), &block)
      end

      def content(**attributes, &block)
        part(:div, "card-content", "flex min-w-0 flex-col gap-content", attributes, &block)
      end

      def footer(**attributes, &block)
        part(:div, "card-footer", "flex min-w-0 flex-wrap items-center justify-end gap-related", attributes, &block)
      end
    end

    # Splats into a control as `**field`, so the control gets the field's id and validation attributes.
    class Field < Base
      attr_reader :id

      def initialize(view, id, control)
        super(view)
        @id = id
        @control = control
      end

      def to_hash = @control
    end

    # trigger yields the attributes that wire an element to open the panel, merged with the ones passed
    # to it, and the element it renders replaces the default trigger. Shared by menus and dialogs.
    module CustomTrigger
      attr_reader :rendered_trigger

      def trigger(**attributes, &block)
        raise ArgumentError, "trigger needs a block that renders the trigger element" unless block

        @rendered_trigger = view.capture(view.send(:lc_attributes, attributes, {}, @wiring), &block)
        nil
      end
    end

    class Dialog < Base
      include CustomTrigger

      attr_reader :header_actions

      def initialize(view, id, close_action = "lc-dialog#close")
        super(view)
        @id = id
        @close_action = close_action
        @wiring = { aria: { haspopup: "dialog", controls: id }, data: { action: "lc-dialog#open" } }
      end

      # Content placed in the header, before the close button. Renders nothing where it is called.
      def actions(&block)
        @header_actions = view.capture(&block)
        nil
      end

      def footer(**attributes, &block)
        part(:div, "dialog-footer", "flex flex-wrap items-center justify-end gap-related", attributes, &block)
      end

      def close(label = nil, variant: :secondary, **attributes)
        label ||= view.send(:lc_t, "lostcoords.ui.dialog.cancel")
        view.lc_button(label, variant: variant, **merge({ data: { action: @close_action, slot: "dialog-close" } }, attributes))
      end
    end

    class Alert < Base
      def actions(**attributes, &block)
        part(:div, "alert-actions", "flex flex-wrap items-center gap-related pt-tight", attributes, &block)
      end
    end

    class Tabs < Base
      Panel = Data.define(:value, :label, :content, :attributes)

      attr_reader :panels

      def initialize(view)
        super
        @panels = []
      end

      # Records a panel; lc_tabs renders the tab list and panels after the block.
      def panel(label, value: nil, **attributes, &block)
        value = (value || label).to_s
        raise ArgumentError, "tab label must not be blank" if label.blank?
        raise ArgumentError, "duplicate tab value: #{value}" if @panels.any? { |panel| panel.value == value }

        @panels << Panel.new(value, label, (view.capture(&block) if block), attributes)
        nil
      end
    end

    class Collapsible < Base
      attr_reader :summary_content, :summary_attributes

      def initialize(view)
        super
        @summary_attributes = {}
      end

      # Records the summary; lc_collapsible renders it before the content.
      def summary(**attributes, &block)
        @summary_content = view.capture(&block)
        @summary_attributes = attributes
        nil
      end
    end

    class NavList < Base
      def initialize(view, compact, layout, indicator)
        super(view)
        @compact = compact
        @layout = layout
        @indicator = indicator
      end

      # current: marks the page the reader is on with aria-current="page". icon: names an icon before
      # the label; a block replaces both, as in `nav.link(url) { … }`. Outside the column layout the
      # item takes no box, so a class that hides the link removes its cell too.
      def link(label = nil, url = nil, icon: nil, current: false, indent: false, **attributes, &block)
        if block
          url = label
          content = view.capture(&block)
        else
          view.send(:lc_label!, label, :label)
          content = icon ? view.safe_join([ view.lc_icon(icon, options: { aria: { hidden: true } }), view.tag.span(label) ]) : label
        end
        raise ArgumentError, "nav link needs a URL" if url.blank?

        data = { slot: "nav-link", lc_nav_target: ("link" if @indicator), action: ("lc-nav#select" if @indicator) }.compact
        view.tag.li(class: view.lc_tw(("contents" unless @layout == :column), ("ps-content" if indent)).presence, data: { slot: "nav-item" }) do
          view.link_to(content, url, **merge({ class: view.lc_nav_link_class(compact: @compact, layout: @layout), aria: { current: ("page" if current) }, data: data }, attributes))
        end
      end

      # The list is named with aria-label rather than an id, so the same navigation can render twice,
      # as in a sidebar and a phone menu.
      def group(title, **attributes, &block)
        part(:li, "nav-group", "flex flex-col gap-tight not-first:pt-section", attributes) do
          view.safe_join([
            view.tag.span(title, class: "px-3 pb-tight text-caption font-semibold text-foreground", aria: { hidden: true }, data: { slot: "nav-group-title" }),
            view.tag.ul(view.capture(&block), class: "m-0 flex list-none flex-col gap-px p-0", aria: { label: title })
          ])
        end
      end
    end

    class TabBar < Base
      LINK = "flex justify-center px-content text-small text-muted-foreground no-underline transition-colors duration-(--lc-motion-quick) " \
        "hover:bg-accent hover:text-foreground aria-[current=page]:font-semibold aria-[current=page]:text-foreground"

      def initialize(view, fill)
        super(view)
        @fill = fill
      end

      # current: marks the tab of the page the reader is on with aria-current="page". count: shows a
      # muted number after the label; nil shows none.
      def link(label, url, current: false, count: nil, **attributes)
        view.send(:lc_label!, label, :label)
        raise ArgumentError, "tab bar link needs a URL" if url.blank?

        view.tag.li(class: (@fill ? "min-w-fit flex-1" : "shrink-0"), data: { slot: "tab-bar-item" }) do
          view.link_to(url, **merge({ class: LINK, aria: { current: ("page" if current) }, data: { slot: "tab-bar-link" } }, attributes)) do
            view.tag.span(class: "relative flex items-center gap-tight py-content whitespace-nowrap") do
              view.safe_join([
                label,
                (view.tag.span(count, class: "font-normal tabular-nums text-muted-foreground", data: { slot: "tab-bar-count" }) unless count.nil?),
                (view.tag.span(class: "absolute inset-x-0 bottom-0 h-1 rounded-pill bg-(--lc-tab-bar-indicator,var(--primary))", aria: { hidden: true }, data: { slot: "tab-bar-indicator" }) if current)
              ].compact)
            end
          end
        end
      end
    end

    class Toc < Base
      LINK = "relative block py-tight ps-content pe-tight text-small text-muted-foreground no-underline transition-colors " \
        "duration-(--lc-motion-quick) hover:text-foreground aria-[current=location]:font-medium aria-[current=location]:text-foreground"

      # url: an in-page anchor such as "#usage". indent: true nests the entry under the one above it.
      def link(label, url, indent: false, **attributes)
        view.send(:lc_label!, label, :label)
        raise ArgumentError, "toc link needs an anchor URL, such as \"#usage\"" unless url.to_s.match?(/#./)

        view.tag.li(data: { slot: "toc-item" }) do
          view.link_to(label, url, **merge({ class: view.lc_tw(LINK, ("ps-[calc(var(--spacing-content)*2)]" if indent)),
            data: { slot: "toc-link", lc_toc_target: "link", action: "lc-toc#select" } }, attributes))
        end
      end
    end

    class AppHeader < Base
      # The home link. label: names it for screen readers, since the block is usually a logo.
      def brand(url = "/", label:, **attributes, &block)
        view.send(:lc_label!, label, :label)
        raise ArgumentError, "header brand needs a block" unless block

        view.link_to(url, **merge({ class: "flex min-h-11 shrink-0 items-center gap-related pe-2 font-semibold tracking-tight text-inherit no-underline",
          aria: { label: label }, data: { slot: "app-header-brand" } }, attributes), &block)
      end

      # A row of links with a sliding indicator; yields the lc_nav_list builder. Hide it on phones
      # with class: "max-sm:hidden" when a dock or menu carries the same links.
      def nav(label: view.send(:lc_t, "lostcoords.ui.app_header.navigation"), **attributes, &block)
        view.lc_nav_list(label: label, layout: :row, indicator: true, **attributes, &block)
      end

      # Controls at the end of the bar, such as search, a theme switch or an account menu.
      def actions(**attributes, &block)
        part(:div, "app-header-actions", "ms-auto flex shrink-0 items-center gap-related", attributes, &block)
      end
    end

    class Sidebar < Base
      ACCOUNT_TRIGGER = "flex w-full min-w-0 cursor-pointer items-center gap-related rounded-xl lc-squircle px-heading py-related text-start " \
        "transition-colors duration-(--lc-motion-quick) hover:bg-accent aria-expanded:bg-accent lc-rail:justify-center lc-rail:px-0"

      def initialize(view, toggle_label, expanded)
        super(view)
        @toggle_label = toggle_label
        @expanded = expanded
      end

      # The top row: the block, usually a wordmark linking home, then the toggle. On the rail the row
      # stacks; show a short mark there with the lc-rail: variant. toggle: false leaves the toggle out.
      def header(toggle: true, **attributes, &block)
        part(:div, "sidebar-header", "flex items-center justify-between gap-related ps-heading lc-rail:flex-col lc-rail:ps-0", attributes) do
          view.safe_join([ (view.capture(&block) if block), (self.toggle if toggle) ].compact)
        end
      end

      # The button that folds the sidebar to a rail and back. Its label, title and aria-expanded follow the state.
      def toggle(**attributes)
        view.lc_icon_button(@toggle_label, icon: "chevron-double-left", size: :sm,
          **merge({ class: "lc-sidebar__toggle", title: @toggle_label, aria: { expanded: @expanded },
            data: { slot: "sidebar-toggle", action: "lc-sidebar#toggle", lc_sidebar_target: "toggle" } }, attributes))
      end

      # The growing middle, usually an lc_nav_list. On the rail its group titles and link labels stay
      # for screen readers only and the links center their icons; give each link a title:.
      def body(**attributes, &block)
        part(:div, "sidebar-body", "flex min-h-0 flex-1 flex-col gap-content", attributes, &block)
      end

      def footer(**attributes, &block)
        part(:div, "sidebar-footer", "flex min-w-0 flex-col gap-related", attributes, &block)
      end

      # A full-width row that opens an lc_menu of the block's lc_menu_option items: avatar:, the name and
      # a detail line, such as an email. On the rail only the avatar shows. Attributes go to the row.
      def account(name, detail: nil, avatar: nil, id: "sidebar-account", align: :start, **attributes, &block)
        view.send(:lc_label!, name, :name)
        raise ArgumentError, "sidebar account needs a block of menu options" unless block

        text = view.tag.span(class: "min-w-0 grow lc-rail:sr-only", data: { slot: "sidebar-account-text" }) do
          view.safe_join([
            view.tag.span(name, class: "block truncate text-label"),
            (view.tag.span(detail, class: "block truncate text-caption text-muted-foreground") if detail.present?)
          ].compact)
        end
        ellipsis = view.lc_icon("ellipsis-horizontal", options: { class: "size-4 shrink-0 text-muted-foreground lc-rail:hidden", "aria-hidden": true })
        view.lc_menu(id: id, align: align, wrapper_attributes: { class: "flex w-full", data: { slot: "sidebar-account" } }) do |menu|
          menu.trigger(**merge({ class: ACCOUNT_TRIGGER, title: name, data: { slot: "sidebar-account-trigger" } }, attributes)) do |wiring|
            view.tag.button(view.safe_join([ avatar, text, ellipsis ].compact), type: "button", **wiring)
          end
          view.capture(&block)
        end
      end
    end

    class Dock < Base
      # The primary destinations, icon above label; yields the lc_nav_list builder.
      def nav(label:, **attributes, &block)
        view.lc_nav_list(label: label, layout: :dock, indicator: true,
          **merge({ class: view.lc_glass_class(shape: :panel, thick: true, extra: "lc-dock__nav rounded-pill") }, attributes), &block)
      end

      # A round button at the end of the dock whose actions fan out above it. Yields a builder:
      # `menu.action "New note", icon: "pencil-square"`.
      def menu(label:, icon: "plus", id: nil, **attributes, &block)
        view.send(:lc_label!, label, :label)
        raise ArgumentError, "dock menu needs a block" unless block

        id ||= "#{label.parameterize.presence || 'dock'}-menu"
        actions = view.capture(DockMenu.new(view), &block)
        view.tag.div(**merge({ class: "lc-dock__menu", data: { slot: "dock-menu", controller: "lc-menu", lc_menu_lift_value: false } }, attributes)) do
          view.safe_join([
            view.tag.button(view.lc_icon(icon, options: { class: "size-7", "aria-hidden": true }), type: "button",
              class: view.lc_glass_class(shape: :disc, thick: true, extra: "lc-dock__trigger"), aria: { label: label, haspopup: "menu", expanded: false, controls: id },
              data: { slot: "dock-menu-trigger", lc_menu_target: "trigger", action: "lc-menu#toggle" }),
            view.tag.div(id: id, class: "lc-dock__actions", role: "menu", aria: { label: label }, data: { lc_menu_target: "popover" }) do
              view.safe_join([
                view.tag.button(type: "button", class: "lc-dock__scrim", tabindex: -1, aria: { label: view.send(:lc_t, "lostcoords.ui.dock.close", label: label) }, data: { action: "lc-menu#close" }),
                actions
              ])
            end
          ])
        end
      end
    end

    class DockMenu < Base
      def initialize(view)
        super
        @count = 0
      end

      # An action that fans out above the dock button. Pass data: { action: "…" } for your controller;
      # the menu closes after it runs.
      def action(label, icon:, **attributes)
        view.send(:lc_label!, label, :label)
        @count += 1
        defaults = { class: view.lc_glass_class(shape: :disc, thick: true, extra: "lc-dock__action"), data: { slot: "dock-action", action: "lc-menu#close" } }
        view.tag.button(**merge(defaults, attributes), type: "button", role: "menuitem", style: "--lc-dock-action-index: #{@count}") do
          view.safe_join([ view.tag.span(label, class: "lc-dock__action-label"), view.lc_icon(icon, options: { class: "size-6", "aria-hidden": true }) ])
        end
      end
    end

    class Panel < Base
      include CustomTrigger

      def initialize(view, wiring)
        super(view)
        @wiring = wiring
      end
    end

    class DescriptionList < Base
      def item(term, detail = nil, **attributes, &block)
        part(:div, "description-item", "grid min-w-0 gap-tight py-heading sm:grid-cols-[minmax(0,1fr)_minmax(0,2fr)] sm:gap-content", attributes) do
          view.safe_join([
            view.tag.dt(term, class: "text-label text-muted-foreground", data: { slot: "description-term" }),
            view.tag.dd(block ? view.capture(&block) : detail, class: "m-0 min-w-0 text-body text-foreground [overflow-wrap:anywhere]", data: { slot: "description-detail" })
          ])
        end
      end
    end
  end
end
