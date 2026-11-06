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
