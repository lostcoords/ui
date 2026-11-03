module Lostcoords::Ui
  module PrimitivesHelper
    BUTTON_STYLES = {
      primary: :accent,
      secondary: :secondary,
      ghost: :ghost,
      destructive: :danger
    }.freeze

    def lc_button(content = nil, variant: :primary, size: :base, icon: nil, icon_position: :start, **attributes, &block)
      tag.button(lc_button_content(content, icon, icon_position, &block), **lc_button_attributes(variant, size, { type: "button" }, attributes))
    end

    def lc_button_link_to(content = nil, url = nil, variant: :primary, size: :base, icon: nil, icon_position: :start, **attributes, &block)
      attributes = lc_button_attributes(variant, size, {}, attributes)
      raise ArgumentError, "Links cannot be disabled; use lc_button for a disabled control" if attributes[:disabled]

      if block
        url ||= content
        content = capture(&block)
      end

      link_to(lc_button_content(content, icon, icon_position), url, attributes)
    end

    def lc_button_to(content = nil, url = nil, variant: :primary, size: :base, icon: nil, icon_position: :start, **attributes, &block)
      if block
        url ||= content
        content = capture(&block)
      end

      button_to(lc_button_content(content, icon, icon_position), url, lc_button_attributes(variant, size, {}, attributes))
    end

    def lc_icon_button(label, icon:, size: :base, shape: :circle, **attributes)
      size = lc_option!(:size, size, ButtonHelper::ICON_BUTTON_SIZES.keys)
      shape = lc_option!(:shape, shape, ButtonHelper::ICON_BUTTON_SHAPES.keys)
      defaults = { type: "button", class: lc_icon_button_class(size: size, shape: shape), aria: { label: label } }
      attributes = lc_attributes(defaults, attributes)
      accessible_label = attributes.fetch(:"aria-label", attributes.dig(:aria, :label))
      raise ArgumentError, "lc_icon_button requires a nonblank accessible label" if label.blank? || accessible_label.blank?

      tag.button(**attributes) do
        lc_icon(icon, options: { "aria-hidden": true })
      end
    end

    def lc_badge(content = nil, tone: :neutral, **attributes, &block)
      tone = lc_option!(:tone, tone, BadgeHelper::BADGE_TONES.keys)
      tag.span(content, **lc_attributes({ class: lc_badge_class(tone: tone) }, attributes), &block)
    end

    def lc_status_pill(content = nil, tone: :accent, **attributes, &block)
      tone = lc_option!(:tone, tone, BadgeHelper::STATUS_PILL_TONES.keys)
      tag.span(content, **lc_attributes({ class: lc_status_pill_class(tone: tone) }, attributes), &block)
    end

    def lc_eyebrow(content = nil, **attributes, &block)
      tag.span(content, **lc_attributes({ class: lc_eyebrow_class }, attributes), &block)
    end

    def lc_icon_badge(icon:, size: :base, **attributes)
      size = lc_option!(:size, size, BadgeHelper::ICON_BADGE_SIZES.keys)
      tag.span(**lc_attributes({ class: lc_icon_badge_class(size: size) }, attributes)) do
        lc_icon(icon, options: { class: "size-[1em]", "aria-hidden": true })
      end
    end

    def lc_medallion(icon:, size: :sm, tone: :accent, **attributes)
      size = lc_option!(:size, size, BadgeHelper::ICON_MEDALLION_SIZES.keys)
      tone = lc_option!(:tone, tone, BadgeHelper::ICON_MEDALLION_TONES.keys)
      tag.span(**lc_attributes({ class: lc_icon_medallion_class(size: size, tone: tone) }, attributes)) do
        lc_icon(icon, options: { class: "size-1/2", "aria-hidden": true })
      end
    end

    def lc_avatar(content = nil, src: nil, alt: nil, size: :base, ink: false, linked: false, **attributes, &block)
      size = lc_option!(:size, size, BadgeHelper::AVATAR_SIZES.keys)
      defaults = { class: lc_avatar_class(size: size, ink: ink, linked: linked) }
      if src
        tag.img(**lc_attributes(defaults.merge(src: src, alt: alt.to_s, class: lc_tw(defaults[:class], "object-cover")), attributes))
      else
        tag.span(content, **lc_attributes(defaults, attributes), &block)
      end
    end

    def lc_avatar_stack(compact: false, **attributes, &block)
      tag.span(**lc_attributes({ class: lc_avatar_stack_class(compact: compact) }, attributes)) do
        tag.span(class: lc_avatar_stack_row_class, &block)
      end
    end

    def lc_card(href: nil, interactive: false, dense: false, **attributes, &block)
      defaults = { class: lc_card_class(interactive: interactive || !href.nil?, dense: dense) }
      if href.nil?
        tag.div(**lc_attributes(defaults, attributes), &block)
      else
        defaults.merge!(href: href, class: lc_tw(defaults[:class], "block no-underline text-inherit"))
        tag.a(**lc_attributes(defaults, attributes), &block)
      end
    end

    def lc_card_surface(**attributes, &block)
      tag.div(**lc_attributes({ class: lc_card_surface_class }, attributes), &block)
    end

    def lc_form_card(padding: :default, **attributes, &block)
      padding = lc_option!(:padding, padding, CardHelper::FORM_CARD_PADDINGS.keys)
      tag.div(**lc_attributes({ class: lc_form_card_class(padding: padding) }, attributes), &block)
    end

    def lc_empty_state(**attributes, &block)
      tag.div(**lc_attributes({ class: lc_empty_state_class }, attributes), &block)
    end

    def lc_spinner(size: :base, label: "Loading…", **attributes)
      size = lc_option!(:size, size, FeedbackHelper::SPINNER_SIZES.keys)
      defaults = { class: lc_spinner_class(size: size), role: ("status" if label.present?), aria: { hidden: (true if label.blank?) } }
      tag.span(**lc_attributes(defaults, attributes)) do
        tag.span(label, class: "sr-only") if label.present?
      end
    end

    def lc_skeleton(**attributes)
      tag.span(**lc_attributes({ class: lc_tw(lc_skeleton_class, "h-4 w-full"), aria: { hidden: true } }, attributes))
    end

    def lc_form_alert(message, tone: :error, **attributes)
      tone = lc_option!(:tone, tone, FormHelper::FORM_ALERT_ICONS.keys)
      defaults = { class: lc_form_alert_class, role: (tone == :error ? "alert" : "status"), data: { tone: tone } }
      tag.div(**lc_attributes(defaults, attributes)) do
        safe_join([ lc_form_alert_icon(tone: tone), tag.p(message, class: "m-0 min-w-0 text-pretty [overflow-wrap:anywhere]") ])
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
        variant = lc_option!(:variant, variant, BUTTON_STYLES.keys)
        size = lc_option!(:size, size, %i[sm base lg])
        lc_attributes(defaults.merge(class: lc_button_class(variant: BUTTON_STYLES.fetch(variant), size: size)), attributes)
      end
  end
end
