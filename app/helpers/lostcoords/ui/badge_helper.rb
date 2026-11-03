module Lostcoords::Ui
  module BadgeHelper
    ICON_BADGE_BASE =
      "icon-badge squircle grid place-items-center shrink-0 " \
      "size-[var(--icon-badge-size,var(--icon-badge-size-default,--spacing(10)))] " \
      "[border:var(--icon-badge-border,1px_solid_transparent)] " \
      "rounded-[var(--icon-badge-radius,var(--radius-2xl))] " \
      "bg-[var(--icon-badge-bg,var(--paper-2))] " \
      "text-[length:var(--icon-badge-font-size,var(--icon-badge-font-size-default,1.125rem))] leading-none"

    # Sizes set the default, so a context that pins --icon-badge-size still wins.
    ICON_BADGE_SIZES = {
      base: "",
      lg: "[--icon-badge-size-default:--spacing(11)] [--icon-badge-font-size-default:1.25rem]",
      xl: "[--icon-badge-size-default:--spacing(14)] [--icon-badge-font-size-default:1.5rem]"
    }.freeze

    ICON_MEDALLION_BASE = "grid place-items-center shrink-0 rounded-full"

    ICON_MEDALLION_SIZES = {
      sm: "size-6.5",
      lg: "size-12"
    }.freeze

    ICON_MEDALLION_TONES = {
      accent: "bg-sky-soft text-accent",
      neutral: "bg-paper-2",
      leaf: "bg-[color-mix(in_oklab,var(--leaf-soft)_72%,var(--paper))] text-leaf"
    }.freeze

    AVATAR_BASE =
      "avatar grid place-items-center shrink-0 rounded-full font-medium tracking-[var(--avatar-tracking,0.05em)] " \
      "size-[var(--avatar-size,var(--avatar-size-default,--spacing(8)))] " \
      "text-[length:var(--avatar-font-size,var(--avatar-font-size-default,0.75rem))] " \
      "text-[color:var(--avatar-color,var(--ink-on-accent))] " \
      "border-[length:var(--avatar-border,0px)] border-[color:var(--avatar-cutout,var(--paper))]"

    # Sizes set the default, so a context that pins --avatar-size (a stack, a dialog) still wins.
    AVATAR_SIZES = {
      base: "",
      lg: "",
      sm: "[--avatar-size-default:--spacing(6.5)] [--avatar-font-size-default:0.625rem]",
      xl: "[--avatar-size-default:--spacing(24)] [--avatar-font-size-default:1.25rem]"
    }.freeze

    AVATAR_INK = "[--avatar-color:var(--ink)]"

    AVATAR_LINKED = "avatar-ring"

    # Overlapping avatars with a "+N" chip. The stack sets inherited variables rather than styling
    # its avatars, so a context's own `[&_.avatar]:` override still wins. The border cuts each
    # avatar out of the one beneath, so it takes the fill it sits on (--avatar-cutout).
    AVATAR_STACK_BASE =
      "avatar-stack relative inline-flex items-center min-w-0 [&_.avatar]:outline-none " \
      "[--avatar-size:--spacing(8)] [--avatar-border:--spacing(0.5)] [--avatar-ring-gap:1] " \
      "[--transaction-avatar-overlap:--spacing(1.5)]"

    AVATAR_STACK_COMPACT =
      "[--avatar-size:--spacing(4.5)] [--avatar-font-size:0.4375rem] [--avatar-border:0px] [--avatar-ring-gap:2] " \
      "@sm:[--avatar-size:--spacing(5.5)] @sm:[--avatar-font-size:0.5rem] " \
      "[--transaction-avatar-overlap:--spacing(1.25)] [--avatar-stack-padding:0px]"

    # dynamic_avatar_stack_controller marks the leading visible avatar with data-first as it narrows the stack.
    AVATAR_STACK_ROW =
      "avatar-stack__row flex shrink-0 p-[var(--avatar-stack-padding,--spacing(1))] " \
      "[&>.avatar]:-ms-(--transaction-avatar-overlap) [&>.avatar:first-child]:ms-0 [&>.avatar[data-first]]:ms-0"

    EYEBROW_BASE =
      "font-mono uppercase tracking-widest text-xs font-medium text-ink-3"

    BADGE_BASE =
      "inline-flex items-center gap-1 rounded-xl px-2.5 py-1 " \
      "font-body text-xs font-medium whitespace-nowrap"

    BADGE_TONES = {
      neutral: "bg-paper-2 text-ink-2",
      success: "bg-leaf-soft text-leaf",
      warning: "bg-gold-soft text-gold",
      danger: "bg-berry-soft text-berry",
      info: "bg-sky-soft text-sky-deep"
    }.freeze

    STATUS_PILL_BASE =
      "inline-flex items-center rounded-full px-[0.6em] py-[0.15em] " \
      "font-body text-sm font-medium"

    STATUS_PILL_TONES = {
      accent: "bg-sky-soft text-accent",
      danger: "bg-berry-soft text-berry"
    }.freeze

    PILL_BASE =
      "inline-flex items-center justify-center gap-2 rounded-full " \
      "border border-transparent bg-paper-2 " \
      "font-body text-ink-2 whitespace-nowrap cursor-pointer no-underline " \
      "transition-[background-color,border-color,color,transform] duration-[150ms] ease-out " \
      "hover:text-ink active:scale-[0.96] " \
      "[&:is(.active,:has(:checked))]:[background:var(--sky-soft)] [&:is(.active,:has(:checked))]:border-accent " \
      "[&:is(.active,:has(:checked))]:text-accent [&:is(.active,:has(:checked))]:shadow-none " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    PILL_GHOST = "border-dashed border-ink-3/40 [background:none] shadow-none text-ink-3"

    PILL_ROW_BASE =
      "flex flex-wrap items-center gap-y-2 gap-x-2"

    def icon_badge_class(size: :base, extra: nil)
      tw(ICON_BADGE_BASE, ICON_BADGE_SIZES.fetch(size.to_sym), extra)
    end

    def icon_medallion_class(size: :sm, tone: :accent, extra: nil)
      tw(
        ICON_MEDALLION_BASE,
        ICON_MEDALLION_SIZES.fetch(size.to_sym, ICON_MEDALLION_SIZES[:sm]),
        ICON_MEDALLION_TONES.fetch(tone.to_sym, ICON_MEDALLION_TONES[:accent]),
        extra
      )
    end

    def avatar_class(size: :base, ink: false, linked: false, extra: nil)
      tw(AVATAR_BASE, AVATAR_SIZES.fetch(size.to_sym), (AVATAR_INK if ink), (AVATAR_LINKED if linked), extra)
    end

    def avatar_stack_class(compact: false, extra: nil)
      tw(AVATAR_STACK_BASE, (AVATAR_STACK_COMPACT if compact), extra)
    end

    def avatar_stack_row_class(extra: nil)
      tw(AVATAR_STACK_ROW, extra)
    end

    def eyebrow_class(extra: nil)
      tw(EYEBROW_BASE, extra)
    end

    def badge_class(tone: :neutral, extra: nil)
      tw(BADGE_BASE, BADGE_TONES.fetch(tone.to_sym, BADGE_TONES[:neutral]), extra)
    end

    def status_pill_class(tone: :accent, extra: nil)
      tw(STATUS_PILL_BASE, STATUS_PILL_TONES.fetch(tone.to_sym, STATUS_PILL_TONES[:accent]), extra)
    end

    def pill_class(active: false, ghost: false, size: :base, extra: nil)
      tw(
        PILL_BASE,
        ButtonHelper::BUTTON_SIZES.fetch(size.to_sym, ButtonHelper::BUTTON_SIZES[:base]),
        (PILL_GHOST if ghost),
        ("active" if active),
        extra
      )
    end

    def pill_row_class(extra: nil)
      tw(PILL_ROW_BASE, extra)
    end
  end
end
