module Lostcoords::Ui
  module PrimitivesHelper
    def lc_button(content = nil, variant: :primary, size: :md, icon: nil, icon_position: :start, **attributes, &block)
      tag.button(lc_button_content(content, icon, icon_position, &block), **lc_button_attributes(variant, size, { type: "button" }, attributes))
    end

    def lc_button_link_to(content = nil, url = nil, variant: :primary, size: :md, icon: nil, icon_position: :start, **attributes, &block)
      attributes = lc_button_attributes(variant, size, {}, attributes)
      raise ArgumentError, "Links cannot be disabled; use lc_button for a disabled control" if attributes[:disabled]

      if block
        url ||= content
        content = capture(&block)
      end

      link_to(lc_button_content(content, icon, icon_position), url, attributes)
    end

    def lc_button_to(content = nil, url = nil, variant: :primary, size: :md, icon: nil, icon_position: :start, **attributes, &block)
      if block
        url ||= content
        content = capture(&block)
      end

      button_to(lc_button_content(content, icon, icon_position), url, lc_button_attributes(variant, size, {}, attributes))
    end

    def lc_icon_button(label, icon:, size: :md, shape: :circle, **attributes)
      size = lc_option!(:size, size, ButtonHelper::ICON_BUTTON_SIZES.keys)
      shape = lc_option!(:shape, shape, ButtonHelper::ICON_BUTTON_SHAPES.keys)
      defaults = { type: "button", class: lc_icon_button_class(size: size, shape: shape), aria: { label: label }, data: { slot: "icon-button", size: size } }
      attributes = lc_attributes(defaults, attributes)
      accessible_label = attributes.fetch(:"aria-label", attributes.dig(:aria, :label))
      raise ArgumentError, "lc_icon_button requires a nonblank accessible label" if label.blank? || accessible_label.blank?

      tag.button(**attributes) do
        lc_icon(icon, options: { "aria-hidden": true })
      end
    end

    def lc_badge(content = nil, tone: :neutral, **attributes, &block)
      tone = lc_option!(:tone, tone, BadgeHelper::BADGE_TONES.keys)
      tag.span(content, **lc_attributes({ class: lc_badge_class(tone: tone), data: { slot: "badge", tone: tone } }, attributes), &block)
    end

    def lc_icon_badge(icon:, size: :md, shape: :square, tone: :neutral, **attributes)
      tag.span(**lc_attributes({ class: lc_icon_badge_class(size: size, shape: shape, tone: tone), data: { slot: "icon-badge" } }, attributes)) do
        lc_icon(icon, options: { class: "size-[1em]", "aria-hidden": true })
      end
    end

    def lc_avatar(content = nil, src: nil, alt: nil, size: :md, ink: false, linked: false, **attributes, &block)
      size = lc_option!(:size, size, BadgeHelper::AVATAR_SIZES.keys)
      defaults = { class: lc_avatar_class(size: size, ink: ink, linked: linked), data: { slot: "avatar" } }
      if src
        tag.img(**lc_attributes(defaults.merge(src: src, alt: alt.to_s, class: lc_tw(defaults[:class], "object-cover")), attributes))
      else
        tag.span(content, **lc_attributes(defaults, attributes), &block)
      end
    end

    def lc_avatar_stack(compact: false, **attributes, &block)
      tag.span(**lc_attributes({ class: lc_avatar_stack_class(compact: compact), data: { slot: "avatar-stack" } }, attributes)) do
        tag.span(class: lc_avatar_stack_row_class, &block)
      end
    end

    # Yields a card builder with header, title, description, content and footer parts. The card stacks
    # its children with the same inset it pads with.
    def lc_card(href: nil, interactive: false, padding: :md, **attributes, &block)
      defaults = { class: lc_card_class(interactive: interactive || !href.nil?, padding: padding, extra: "flex flex-col gap-inset"), data: { slot: "card" } }
      content = capture(Parts::Card.new(self), &block) if block
      if href.nil?
        tag.div(content, **lc_attributes(defaults, attributes))
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

      def lc_button_attributes(variant, size, defaults, attributes)
        data = { slot: "button", variant: lc_option!(:variant, variant, ButtonHelper::BUTTON_VARIANTS.keys), size: lc_option!(:size, size, ButtonHelper::BUTTON_SIZES.keys) }
        lc_attributes(defaults.merge(class: lc_button_class(variant: variant, size: size), data: data), attributes)
      end
  end
end
