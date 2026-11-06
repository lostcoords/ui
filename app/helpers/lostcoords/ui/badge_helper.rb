module Lostcoords::Ui
  module BadgeHelper
    ICON_BADGE_BASE =
      "lc-icon-badge grid place-items-center shrink-0 " \
      "size-[var(--lc-icon-badge-size,var(--lc-icon-badge-size-default,--spacing(10)))] " \
      "[border:var(--lc-icon-badge-border,1px_solid_transparent)] " \
      "text-[length:var(--lc-icon-badge-font-size,calc(var(--lc-icon-badge-size,var(--lc-icon-badge-size-default,--spacing(10)))*var(--lc-icon-badge-font-scale,var(--lc-icon-badge-font-scale-default,0.45))))] leading-none"

    # Sizes set the defaults, so a context that pins --lc-icon-badge-size still wins and the emoji
    # or icon follows it. --lc-icon-badge-font-scale sets the glyph's share of the badge.
    ICON_BADGE_SIZES = {
      sm: "[--lc-icon-badge-size-default:--spacing(6.5)] [--lc-icon-badge-font-scale-default:0.5]",
      md: "",
      lg: "[--lc-icon-badge-size-default:--spacing(12)] [--lc-icon-badge-font-scale-default:0.5]",
      xl: "[--lc-icon-badge-size-default:--spacing(14)] [--lc-icon-badge-font-scale-default:0.5]",
      # Steps on the spacing scale, as in size-7, for row glyphs between the named sizes.
      6 => "[--lc-icon-badge-size-default:--spacing(6)] [--lc-icon-badge-font-scale-default:0.5]",
      7 => "[--lc-icon-badge-size-default:--spacing(7)] [--lc-icon-badge-font-scale-default:0.5]",
      11 => "[--lc-icon-badge-size-default:--spacing(11)] [--lc-icon-badge-font-scale-default:0.5]"
    }.freeze

    # plain drops the tile: the emoji or icon is the badge, as at the start of a list row.
    ICON_BADGE_SHAPES = { square: "lc-squircle rounded-2xl", circle: "rounded-full", plain: "rounded-none" }.freeze
    ICON_BADGE_PLAIN = "bg-transparent [--lc-icon-badge-font-scale-default:0.875]"

    AVATAR_BASE =
      "lc-avatar grid place-items-center shrink-0 rounded-full font-medium tracking-[var(--lc-avatar-tracking,0.05em)] " \
      "size-[var(--lc-avatar-size,var(--lc-avatar-size-default,--spacing(8)))] " \
      "text-[length:var(--lc-avatar-font-size,calc(var(--lc-avatar-size,var(--lc-avatar-size-default,--spacing(8)))*var(--lc-avatar-font-scale,var(--lc-avatar-font-scale-default,0.375))))] " \
      "text-[color:var(--lc-avatar-color,var(--primary-foreground))] " \
      "border-[length:var(--lc-avatar-border,0px)] border-[color:var(--lc-avatar-cutout,var(--background))]"

    # Sizes set the defaults, so a context that pins --lc-avatar-size (a stack, a dialog) still wins
    # and the initials follow it. --lc-avatar-font-scale sets their share of the avatar.
    AVATAR_SIZES = {
      xs: "[--lc-avatar-size-default:--spacing(5)] [--lc-avatar-font-scale-default:0.4]",
      sm: "[--lc-avatar-size-default:--spacing(6.5)] [--lc-avatar-font-scale-default:0.385]",
      md: "",
      lg: "[--lc-avatar-size-default:--spacing(12)] [--lc-avatar-font-scale-default:0.333]",
      xl: "[--lc-avatar-size-default:--spacing(24)] [--lc-avatar-font-scale-default:0.208]",
      xxl: "[--lc-avatar-size-default:--spacing(28)] [--lc-avatar-font-scale-default:0.25]",
      # Steps on the spacing scale, as in size-7, between the named sizes.
      7 => "[--lc-avatar-size-default:--spacing(7)]",
      11 => "[--lc-avatar-size-default:--spacing(11)] [--lc-avatar-font-scale-default:0.35]"
    }.freeze

    AVATAR_INK = "[--lc-avatar-color:var(--foreground)]"

    AVATAR_LINKED = "lc-avatar-ring"

    # Overlapping avatars with a "+N" chip. The stack sets inherited variables rather than styling
    # its avatars, so a context's own `[&_.lc-avatar]:` override still wins. The border cuts each
    # avatar out of the one beneath, so it takes the fill it sits on (--lc-avatar-cutout).
    AVATAR_STACK_BASE =
      "lc-avatar-stack relative inline-flex items-center min-w-0 [&_.lc-avatar]:outline-none " \
      "[--lc-avatar-size:--spacing(8)] [--lc-avatar-border:--spacing(0.5)] [--lc-avatar-ring-gap:1] " \
      "[--lc-avatar-stack-overlap:--spacing(1.5)]"

    AVATAR_STACK_COMPACT =
      "[--lc-avatar-size:--spacing(4.5)] [--lc-avatar-font-size:0.4375rem] [--lc-avatar-border:0px] [--lc-avatar-ring-gap:2] " \
      "@sm:[--lc-avatar-size:--spacing(5.5)] @sm:[--lc-avatar-font-size:0.5rem] " \
      "[--lc-avatar-stack-overlap:--spacing(1.25)] [--lc-avatar-stack-padding:0px]"

    # dynamic_avatar_stack_controller marks the leading visible avatar with data-first as it narrows the stack.
    AVATAR_STACK_ROW =
      "lc-avatar-stack__row flex shrink-0 p-[var(--lc-avatar-stack-padding,--spacing(1))] " \
      "[&>.lc-avatar]:-ms-(--lc-avatar-stack-overlap) [&>.lc-avatar:first-child]:ms-0 [&>.lc-avatar[data-first]]:ms-0"

    BADGE_BASE =
      "inline-flex items-center gap-tight rounded-lg lc-squircle px-2 py-0.5 " \
      "font-sans text-caption font-medium whitespace-nowrap"

    BADGE_TONES = {
      neutral: "bg-tile text-muted-foreground",
      success: "bg-success-soft text-success",
      warning: "bg-warning-soft text-warning",
      destructive: "bg-destructive-soft text-destructive",
      primary: "bg-primary-soft text-primary"
    }.freeze

    BADGE_SHAPES = { rounded: "", pill: "rounded-full px-2.5" }.freeze

    TOGGLE_BASE =
      "inline-flex items-center justify-center gap-related rounded-pill " \
      "border border-transparent bg-(--lc-field-bg,var(--input)) " \
      "font-sans text-muted-foreground whitespace-nowrap cursor-pointer no-underline " \
      "transition-[background-color,border-color,color,transform] duration-(--lc-motion-quick) ease-(--lc-ease-out) " \
      "lc-press hover:text-foreground " \
      "aria-pressed:bg-primary-soft aria-pressed:border-primary aria-pressed:text-primary aria-pressed:shadow-none " \
      "aria-checked:bg-primary-soft aria-checked:border-primary aria-checked:text-primary aria-checked:shadow-none " \
      "aria-[current]:not-aria-[current=false]:bg-primary-soft aria-[current]:not-aria-[current=false]:border-primary " \
      "aria-[current]:not-aria-[current=false]:text-primary aria-[current]:not-aria-[current=false]:shadow-none " \
      "has-checked:bg-primary-soft has-checked:border-primary has-checked:text-primary has-checked:shadow-none " \
      "aria-expanded:bg-primary-soft aria-expanded:border-primary aria-expanded:text-primary aria-expanded:shadow-none " \
      "[&_svg]:size-[1.1em] [&_svg]:shrink-0"

    TOGGLE_ACTIVE = "bg-primary-soft border-primary text-primary hover:text-primary shadow-none"

    TOGGLE_GHOST = "border-dashed border-muted-foreground/40 [background:none] shadow-none text-muted-foreground"

    def lc_icon_badge_class(size: :md, shape: :square, tone: :neutral, extra: nil)
      size = lc_option!(:size, size, ICON_BADGE_SIZES.keys)
      shape = lc_option!(:shape, shape, ICON_BADGE_SHAPES.keys)
      tone = lc_option!(:tone, tone, BADGE_TONES.keys)
      lc_tw(ICON_BADGE_BASE, ICON_BADGE_SIZES.fetch(size), ICON_BADGE_SHAPES.fetch(shape),
        (tone == :neutral ? "bg-tile text-foreground" : BADGE_TONES.fetch(tone)), (ICON_BADGE_PLAIN if shape == :plain), extra)
    end

    def lc_avatar_class(size: :md, ink: false, linked: false, extra: nil)
      lc_tw(AVATAR_BASE, AVATAR_SIZES.fetch(lc_option!(:size, size, AVATAR_SIZES.keys)), (AVATAR_INK if ink), (AVATAR_LINKED if linked), extra)
    end

    def lc_avatar_stack_class(compact: false, extra: nil)
      lc_tw(AVATAR_STACK_BASE, (AVATAR_STACK_COMPACT if compact), extra)
    end

    def lc_avatar_stack_row_class(extra: nil)
      lc_tw(AVATAR_STACK_ROW, extra)
    end

    def lc_badge_class(tone: :neutral, shape: :rounded, extra: nil)
      tone = lc_option!(:tone, tone, BADGE_TONES.keys)
      shape = lc_option!(:shape, shape, BADGE_SHAPES.keys)
      lc_tw(BADGE_BASE, BADGE_SHAPES.fetch(shape), BADGE_TONES.fetch(tone), extra)
    end

    def lc_toggle_class(active: false, ghost: false, size: :md, extra: nil)
      lc_tw(
        TOGGLE_BASE,
        ButtonHelper::BUTTON_SIZES.fetch(lc_option!(:size, size, ButtonHelper::BUTTON_SIZES.keys)),
        (TOGGLE_GHOST if ghost),
        (TOGGLE_ACTIVE if active),
        extra
      )
    end
  end
end
