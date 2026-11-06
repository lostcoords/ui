module Lostcoords::Ui
  module PrimitivesHelper
    BUTTON_EXPANDED_SWAP = "[&>[data-slot=button-expanded-icon]]:hidden aria-expanded:[&>[data-slot=button-label]]:sr-only aria-expanded:[&>[data-slot=button-expanded-icon]]:block"

    # as: :span renders the look without a control, for a decorative button inside a larger target
    # such as a file drop zone's label. expanded_icon: swaps the content for that icon while
    # aria-expanded is true; the content stays as the accessible name.
    def lc_button(content = nil, variant: :primary, tone: :default, size: :md, block: false, icon: nil, icon_position: :start, as: :button, expanded_icon: nil, **attributes, &content_block)
      as = lc_option!(:as, as, %i[button span])
      content = lc_button_content(content, icon, icon_position, &content_block)
      if expanded_icon
        content = safe_join([
          tag.span(content, class: "inline-flex items-center gap-related", data: { slot: "button-label" }),
          lc_icon(expanded_icon, options: { "aria-hidden": true, "data-slot": "button-expanded-icon" })
        ])
        attributes = lc_attributes({ class: BUTTON_EXPANDED_SWAP }, attributes)
      end
      attributes = lc_button_attributes(variant, tone, size, block, (as == :button ? { type: "button" } : {}), attributes)
      tag.public_send(as, content, **attributes)
    end

    def lc_button_link_to(content = nil, url = nil, variant: :primary, tone: :default, size: :md, block: false, icon: nil, icon_position: :start, **attributes, &content_block)
      attributes = lc_button_attributes(variant, tone, size, block, {}, attributes)
      raise ArgumentError, "Links cannot be disabled; use lc_button for a disabled control" if attributes[:disabled]

      if content_block
        url ||= content
        content = capture(&content_block)
      end

      link_to(lc_button_content(content, icon, icon_position), url, attributes)
    end

    def lc_button_to(content = nil, url = nil, variant: :primary, tone: :default, size: :md, block: false, icon: nil, icon_position: :start, **attributes, &content_block)
      if content_block
        url ||= content
        content = capture(&content_block)
      end

      button_to(lc_button_content(content, icon, icon_position), url, lc_button_attributes(variant, tone, size, block, {}, attributes))
    end

    # A button styled as a select for opening a menu or picker. A string label truncates; a block
    # renders its own content, such as an avatar and a label. The chevron is appended either way.
    def lc_select_trigger(label = nil, size: :md, block: false, **attributes, &content)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      body = content ? capture(&content) : tag.span(label, class: "min-w-0 truncate")
      chevron = lc_icon("chevron-down", variant: :mini, options: { "aria-hidden": true, "data-icon": "inline-end" })
      defaults = { type: "button", class: lc_select_trigger_class(size: size, block: block), data: { slot: "select-trigger", size: size } }
      tag.button(safe_join([ body, chevron ]), **lc_attributes(defaults, attributes))
    end

    # A block replaces the icon with custom content, such as an avatar or two stacked icons.
    # One pill with a primary action and a toggle on its inline end that opens a menu of the block's
    # lc_menu_option items. With href: the action is a link. label may be rendered HTML. action:,
    # toggle: and menu: add attributes to those parts; other attributes go on the wrapper.
    #
    #   <%= lc_split_button "Add expense", id: "add", href: new_expense_path, icon: "plus", menu_label: "More ways to add" do %>
    #     <%= lc_menu_option "Import a CSV", icon: "arrow-down-tray" %>
    #   <% end %>
    def lc_split_button(label, id:, href: nil, menu_label: lc_t("lostcoords.ui.menu.label"), variant: :primary, tone: :default, size: :md,
                        icon: nil, icon_position: :start, block: false, align: :end, action: {}, toggle: {}, menu: {}, **attributes, &items)
      lc_label!(id, :id)
      lc_label!(menu_label, :menu_label)
      variant = lc_option!(:variant, variant, ButtonHelper::BUTTON_VARIANTS.keys)
      size = lc_option!(:size, size, ButtonHelper::BUTTON_SIZES.keys)
      button = { variant: variant, tone: tone, size: size, icon: icon, icon_position: icon_position }
      action = lc_attributes({ class: lc_tw(ButtonHelper::SPLIT_BUTTON_PART, ButtonHelper::SPLIT_BUTTON_ACTION) }, action)
      primary = href ? lc_button_link_to(label, href, **button, **action) : lc_button(label, **button, **action)

      toggle_class = lc_button_class(variant: variant, tone: tone, size: size, extra: lc_tw(
        ButtonHelper::SPLIT_BUTTON_PART, ButtonHelper::SPLIT_BUTTON_TOGGLE, ButtonHelper::SPLIT_BUTTON_TOGGLE_WIDTHS.fetch(size),
        (ButtonHelper::SPLIT_BUTTON_DIVIDER unless variant == :outline)
      ))
      toggle = tag.button(lc_icon("chevron-down", variant: :mini, options: { "aria-hidden": true }), **lc_attributes(
        { type: "button", class: toggle_class, data: { slot: "split-button-toggle", action: "lc-menu#toggle" } }, toggle,
        { id: "#{id}-trigger", aria: { label: menu_label, haspopup: "menu", expanded: false, controls: id }, data: { lc_menu_target: "trigger" } }
      ))

      popover = tag.div(capture(&items), **lc_attributes(
        { class: lc_menu_popover_class(align: align), data: { slot: "menu" } }, menu,
        { id: id, role: "menu", aria: { labelledby: "#{id}-trigger" }, data: { lc_menu_target: "popover" } }
      ))

      defaults = { class: lc_tw(ButtonHelper::SPLIT_BUTTON_BASE, ("flex w-full" if block)), data: { controller: "lc-menu", slot: "split-button" } }
      tag.div(safe_join([ primary, toggle, popover ]), **lc_attributes(defaults, attributes))
    end

    def lc_icon_button(label, icon: nil, size: :md, shape: :circle, variant: :ghost, tone: :default, **attributes, &content)
      attributes = lc_icon_button_attributes(label, size, shape, variant, tone, { type: "button" }, attributes)
      tag.button(lc_icon_button_content(icon, &content), **attributes)
    end

    def lc_icon_button_link_to(label, url, icon: nil, size: :md, shape: :circle, variant: :ghost, tone: :default, **attributes, &content)
      attributes = lc_icon_button_attributes(label, size, shape, variant, tone, {}, attributes)
      raise ArgumentError, "Links cannot be disabled; use lc_icon_button for a disabled control" if attributes[:disabled]

      link_to(lc_icon_button_content(icon, &content), url, attributes)
    end

    def lc_icon_button_to(label, url, icon: nil, size: :md, shape: :circle, variant: :ghost, tone: :default, **attributes, &content)
      button_to(lc_icon_button_content(icon, &content), url, lc_icon_button_attributes(label, size, shape, variant, tone, {}, attributes))
    end

    def lc_badge(content = nil, tone: :neutral, shape: :rounded, **attributes, &block)
      tone = lc_option!(:tone, tone, BadgeHelper::BADGE_TONES.keys)
      tag.span(content, **lc_attributes({ class: lc_badge_class(tone: tone, shape: shape), data: { slot: "badge", tone: tone } }, attributes), &block)
    end

    # Pass icon: for a library icon, or content or a block for an emoji or a custom glyph.
    def lc_icon_badge(content = nil, icon: nil, size: :md, shape: :square, tone: :neutral, **attributes, &block)
      raise ArgumentError, "Pass icon:, content or a block, not more than one" if [ icon, content, block ].compact.size > 1

      tag.span(**lc_attributes({ class: lc_icon_badge_class(size: size, shape: shape, tone: tone), data: { slot: "icon-badge" } }, attributes)) do
        icon ? lc_icon(icon, options: { class: "size-[1em]", "aria-hidden": true }) : block ? capture(&block) : content
      end
    end

    # as: :button makes the avatar itself the control, such as a picker's trigger.
    def lc_avatar(content = nil, src: nil, alt: nil, size: :md, ink: false, linked: false, as: :span, **attributes, &block)
      size = lc_option!(:size, size, BadgeHelper::AVATAR_SIZES.keys)
      as = lc_option!(:as, as, %i[span button])
      defaults = { class: lc_avatar_class(size: size, ink: ink, linked: linked), data: { slot: "avatar" } }
      if src
        tag.img(**lc_attributes(defaults.merge(src: src, alt: alt.to_s, class: lc_tw(defaults[:class], "object-cover")), attributes))
      elsif as == :button
        defaults.merge!(type: "button", class: lc_tw(defaults[:class], "cursor-pointer border-0 p-0"))
        tag.button(content, **lc_attributes(defaults, attributes), &block)
      else
        tag.span(content, **lc_attributes(defaults, attributes), &block)
      end
    end

    # row: takes attributes for the inner row that overlaps the avatars, such as a controller target.
    def lc_avatar_stack(compact: false, row: {}, **attributes, &block)
      tag.span(**lc_attributes({ class: lc_avatar_stack_class(compact: compact), data: { slot: "avatar-stack" } }, attributes)) do
        tag.span(**lc_attributes({ class: lc_avatar_stack_row_class }, row), &block)
      end
    end

    CARD_ELEMENTS = %i[div section article aside li form].freeze

    # Yields a card builder with header, title, description, content and footer parts. The card stacks
    # its children with the same inset it pads with; an unpadded card's children meet edge to edge.
    def lc_card(href: nil, interactive: false, padding: :md, as: :div, **attributes, &block)
      defaults = { class: lc_card_class(interactive: interactive || !href.nil?, padding: padding, extra: [ "flex flex-col", ("gap-inset" unless padding.to_s == "none") ]), data: { slot: "card" } }
      content = capture(Parts::Card.new(self), &block) if block
      if href.nil?
        tag.public_send(lc_option!(:as, as, CARD_ELEMENTS), content, **lc_attributes(defaults, attributes))
      else
        defaults.merge!(href: href, class: lc_tw(defaults[:class], "no-underline text-inherit"))
        tag.a(content, **lc_attributes(defaults, attributes))
      end
    end

    def lc_empty_state(**attributes, &block)
      tag.div(**lc_attributes({ class: lc_empty_state_class, data: { slot: "empty-state" } }, attributes), &block)
    end

    def lc_spinner(size: :md, label: lc_t("lostcoords.ui.spinner.label"), **attributes)
      size = lc_option!(:size, size, FeedbackHelper::SPINNER_SIZES.keys)
      defaults = { class: lc_spinner_class(size: size), role: ("status" if label.present?), aria: { hidden: (true if label.blank?) }, data: { slot: "spinner" } }
      tag.span(**lc_attributes(defaults, attributes)) do
        tag.span(label, class: "sr-only") if label.present?
      end
    end

    def lc_skeleton(**attributes)
      tag.span(**lc_attributes({ class: lc_tw(lc_skeleton_class, "h-4 w-full"), aria: { hidden: true }, data: { slot: "skeleton" } }, attributes))
    end

    # A block adds content below the message and yields a builder with an actions part.
    def lc_alert(message = nil, title: nil, tone: :destructive, **attributes, &block)
      tone = lc_option!(:tone, tone, FeedbackHelper::ALERT_ICONS.keys)
      raise ArgumentError, "lc_alert needs a message, a title or a block" if message.blank? && title.blank? && block.nil?

      defaults = { class: lc_alert_class, role: (tone == :destructive ? "alert" : "status"), data: { tone: tone, slot: "alert" } }
      extra = capture(Parts::Alert.new(self), &block) if block
      text = "m-0 min-w-0 text-pretty [overflow-wrap:anywhere]"
      tag.div(**lc_attributes(defaults, attributes)) do
        body = [
          (tag.p(title, class: "#{text} font-semibold", data: { slot: "alert-title" }) if title.present?),
          (tag.p(message, class: lc_tw(text, ("font-normal" if title.present?)), data: { slot: "alert-description" }) if message.present?),
          extra.presence
        ].compact
        safe_join([ lc_alert_icon(tone: tone), tag.div(safe_join(body), class: "flex min-w-0 flex-col gap-tight") ])
      end
    end

    private
      def lc_button_content(content, icon, position, &block)
        position = lc_option!(:icon_position, position, %i[start end])
        content = capture(&block) if block
        return content unless icon

        glyph = lc_icon(icon, options: { "aria-hidden": true, "data-icon": "inline-#{position}" })
        safe_join(position == :start ? [ glyph, content ] : [ content, glyph ])
      end

      def lc_button_attributes(variant, tone, size, block, defaults, attributes)
        tone = lc_option!(:tone, tone, ButtonHelper::BUTTON_TONES.keys)
        data = { slot: "button", variant: lc_option!(:variant, variant, ButtonHelper::BUTTON_VARIANTS.keys), tone: (tone unless tone == :default), size: lc_option!(:size, size, ButtonHelper::BUTTON_SIZES.keys) }
        lc_attributes(defaults.merge(class: lc_button_class(variant: variant, tone: tone, size: size, block: block), data: data), attributes)
      end

      def lc_icon_button_attributes(label, size, shape, variant, tone, defaults, attributes)
        size = lc_option!(:size, size, ButtonHelper::ICON_BUTTON_SIZES.keys)
        shape = lc_option!(:shape, shape, ButtonHelper::ICON_BUTTON_SHAPES.keys)
        data = { slot: "icon-button", size: size, variant: (variant.to_sym unless variant.to_sym == :ghost), tone: (tone.to_sym unless tone.to_sym == :default) }.compact
        defaults = defaults.merge(class: lc_icon_button_class(size: size, shape: shape, variant: variant, tone: tone), aria: { label: label }, data: data)
        attributes = lc_attributes(defaults, attributes)
        accessible_label = attributes.fetch(:"aria-label", attributes.dig(:aria, :label))
        raise ArgumentError, "lc_icon_button requires a nonblank accessible label" if label.blank? || accessible_label.blank?

        attributes
      end

      def lc_icon_button_content(icon, &content)
        raise ArgumentError, "Pass icon: or a block" unless icon || content

        content ? capture(&content) : lc_icon(icon, options: { "aria-hidden": true })
      end
  end
end
