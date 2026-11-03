module Lostcoords::Ui
  module PrimitivesHelper
    BUTTON_STYLES = {
      primary: :accent,
      secondary: :secondary,
      ghost: :ghost,
      destructive: :danger
    }.freeze

    def ui_button(content = nil, variant: :primary, size: :base, **attributes, &block)
      tag.button(content, **ui_button_attributes(variant, size, { type: "button" }, attributes), &block)
    end

    def ui_button_link_to(content = nil, url = nil, variant: :primary, size: :base, **attributes, &block)
      attributes = ui_button_attributes(variant, size, {}, attributes)
      raise ArgumentError, "Links cannot be disabled; use ui_button for a disabled control" if attributes[:disabled]

      if block
        url ||= content
        content = capture(&block)
      end

      link_to(content, url, attributes)
    end

    def ui_button_to(content = nil, url = nil, variant: :primary, size: :base, **attributes, &block)
      if block
        url ||= content
        content = capture(&block)
      end

      button_to(content, url, ui_button_attributes(variant, size, {}, attributes))
    end

    def ui_icon_button(label, icon:, size: :base, shape: :circle, **attributes)
      size = ui_option!(:size, size, ButtonHelper::ICON_BUTTON_SIZES.keys)
      shape = ui_option!(:shape, shape, ButtonHelper::ICON_BUTTON_SHAPES.keys)
      defaults = { type: "button", class: icon_button_class(size: size, shape: shape), aria: { label: label } }
      attributes = ui_attributes(defaults, attributes)
      accessible_label = attributes.fetch(:"aria-label", attributes.dig(:aria, :label))
      raise ArgumentError, "ui_icon_button requires a nonblank accessible label" if label.blank? || accessible_label.blank?

      tag.button(**attributes) do
        heroicon(icon, options: { "aria-hidden": true })
      end
    end

    def ui_badge(content = nil, tone: :neutral, **attributes, &block)
      tone = ui_option!(:tone, tone, BadgeHelper::BADGE_TONES.keys)
      tag.span(content, **ui_attributes({ class: badge_class(tone: tone) }, attributes), &block)
    end

    def ui_status_pill(content = nil, tone: :accent, **attributes, &block)
      tone = ui_option!(:tone, tone, BadgeHelper::STATUS_PILL_TONES.keys)
      tag.span(content, **ui_attributes({ class: status_pill_class(tone: tone) }, attributes), &block)
    end

    def ui_eyebrow(content = nil, **attributes, &block)
      tag.span(content, **ui_attributes({ class: eyebrow_class }, attributes), &block)
    end

    def ui_icon_badge(icon:, size: :base, **attributes)
      size = ui_option!(:size, size, BadgeHelper::ICON_BADGE_SIZES.keys)
      tag.span(**ui_attributes({ class: icon_badge_class(size: size) }, attributes)) do
        heroicon(icon, options: { class: "size-[1em]", "aria-hidden": true })
      end
    end

    def ui_medallion(icon:, size: :sm, tone: :accent, **attributes)
      size = ui_option!(:size, size, BadgeHelper::ICON_MEDALLION_SIZES.keys)
      tone = ui_option!(:tone, tone, BadgeHelper::ICON_MEDALLION_TONES.keys)
      tag.span(**ui_attributes({ class: icon_medallion_class(size: size, tone: tone) }, attributes)) do
        heroicon(icon, options: { class: "size-1/2", "aria-hidden": true })
      end
    end

    def ui_avatar(content = nil, src: nil, alt: nil, size: :base, ink: false, linked: false, **attributes, &block)
      size = ui_option!(:size, size, BadgeHelper::AVATAR_SIZES.keys)
      defaults = { class: avatar_class(size: size, ink: ink, linked: linked) }
      if src
        tag.img(**ui_attributes(defaults.merge(src: src, alt: alt.to_s, class: tw(defaults[:class], "object-cover")), attributes))
      else
        tag.span(content, **ui_attributes(defaults, attributes), &block)
      end
    end

    def ui_avatar_stack(compact: false, **attributes, &block)
      tag.span(**ui_attributes({ class: avatar_stack_class(compact: compact) }, attributes)) do
        tag.span(class: avatar_stack_row_class, &block)
      end
    end

    def ui_card(href: nil, interactive: false, dense: false, **attributes, &block)
      defaults = { class: card_class(interactive: interactive || !href.nil?, dense: dense) }
      if href.nil?
        tag.div(**ui_attributes(defaults, attributes), &block)
      else
        defaults.merge!(href: href, class: tw(defaults[:class], "block no-underline text-inherit"))
        tag.a(**ui_attributes(defaults, attributes), &block)
      end
    end

    def ui_card_surface(**attributes, &block)
      tag.div(**ui_attributes({ class: card_surface_class }, attributes), &block)
    end

    def ui_form_card(padding: :default, **attributes, &block)
      padding = ui_option!(:padding, padding, CardHelper::FORM_CARD_PADDINGS.keys)
      tag.div(**ui_attributes({ class: form_card_class(padding: padding) }, attributes), &block)
    end

    def ui_empty_state(**attributes, &block)
      tag.div(**ui_attributes({ class: empty_state_class }, attributes), &block)
    end

    def ui_spinner(size: :base, label: "Loading…", **attributes)
      size = ui_option!(:size, size, FeedbackHelper::SPINNER_SIZES.keys)
      defaults = { class: spinner_class(size: size), role: ("status" if label.present?), aria: { hidden: (true if label.blank?) } }
      tag.span(**ui_attributes(defaults, attributes)) do
        tag.span(label, class: "sr-only") if label.present?
      end
    end

    def ui_skeleton(**attributes)
      tag.span(**ui_attributes({ class: tw(skeleton_class, "h-4 w-full"), aria: { hidden: true } }, attributes))
    end

    def ui_form_alert(message, tone: :error, **attributes)
      tone = ui_option!(:tone, tone, FormHelper::FORM_ALERT_ICONS.keys)
      defaults = { class: form_alert_class, role: (tone == :error ? "alert" : "status"), data: { tone: tone } }
      tag.div(**ui_attributes(defaults, attributes)) do
        safe_join([ form_alert_icon(tone: tone), tag.p(message, class: "m-0 min-w-0 text-pretty [overflow-wrap:anywhere]") ])
      end
    end

    private
      def ui_button_attributes(variant, size, defaults, attributes)
        variant = ui_option!(:variant, variant, BUTTON_STYLES.keys)
        size = ui_option!(:size, size, %i[sm base lg])
        ui_attributes(defaults.merge(class: button_class(variant: BUTTON_STYLES.fetch(variant), size: size)), attributes)
      end
  end
end
