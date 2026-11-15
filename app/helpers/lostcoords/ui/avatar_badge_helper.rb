module Lostcoords::Ui
  module AvatarBadgeHelper
    AVATAR_BADGE_BASE = "absolute -bottom-1 -end-1 grid place-items-center rounded-full bg-background"

    # :sm is a status mark, such as a lock; :md is the 44px control size.
    AVATAR_BADGE_SIZES = {
      sm: "size-7 text-muted-foreground ring-1 ring-border shadow-(--lc-shadow-sm) [&_svg]:size-4",
      md: "size-11 text-foreground shadow-(--lc-shadow) [&_svg]:size-5"
    }.freeze

    AVATAR_BADGE_CONTROL = "cursor-pointer border-0 p-0 transition-colors hover:bg-muted"
    AVATAR_BADGE_TAGS = %i[span button label].freeze

    def lc_avatar_badge_class(size: :md, control: false, extra: nil)
      size = lc_option!(:size, size, AVATAR_BADGE_SIZES.keys)
      lc_tw(AVATAR_BADGE_BASE, AVATAR_BADGE_SIZES.fetch(size), (AVATAR_BADGE_CONTROL if control), extra)
    end

    # A round badge on an avatar's bottom corner. Render it after the avatar inside a `relative` wrapper.
    # as: :span is a decorative mark (size :sm by default); :button and :label are 44px controls named by
    # label:. A :label needs for:, and shows the focus halo while the visually hidden input after it has focus.
    # Inside menu.trigger, splat the yielded attributes into an as: :button badge.
    def lc_avatar_badge(icon, label: nil, as: :span, size: nil, **attributes)
      as = lc_option!(:as, as, AVATAR_BADGE_TAGS)
      control = as != :span
      size = lc_option!(:size, size || (control ? :md : :sm), AVATAR_BADGE_SIZES.keys)
      raise ArgumentError, "a #{as} badge is a 44px control; use size: :md" if control && size != :md
      lc_label!(label, :label) if control
      raise ArgumentError, "as: :label needs for:" if as == :label && attributes[:for].blank?

      glyph = lc_icon(icon, variant: (size == :sm ? :mini : :outline), options: { "aria-hidden": true })
      defaults = { class: lc_avatar_badge_class(size: size, control: control), data: { slot: "avatar-badge" } }
      case as
      when :button
        tag.button(glyph, **lc_attributes(defaults.merge(type: "button", aria: { label: label }), attributes))
      when :label
        tag.label(safe_join([ glyph, tag.span(label, class: "sr-only") ]), **lc_attributes(defaults.merge(title: label), attributes))
      else
        tag.span(glyph, **lc_attributes(defaults.merge(aria: (label ? { label: label } : { hidden: true }), role: ("img" if label)), attributes))
      end
    end
  end
end
