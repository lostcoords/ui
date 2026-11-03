module Lostcoords::Ui
  module GlassHelper
    # Menus lift further, and on phones go solid: they cover rows that look like their own
    # options, and some open where nothing blurs (the dock). Dark lifts to surface-hover to clear cards.
    GLASS_MENU = "[--lc-glass-shadow:var(--lc-glass-rim),var(--lc-shadow-lg)] max-md:[--lc-glass-fill:var(--background)] dark:max-md:[--lc-glass-fill:var(--accent)]"

    GLASS_SHAPES = {
      bar: "rounded-full border-(--lc-glass-bar-edge)",
      panel: "rounded-3xl",
      disc: "rounded-full",
      menu: "rounded-3xl #{GLASS_MENU}",
      # A picker is a menu on desktop and a bottom sheet on phones, so its own CSS owns the corners.
      picker: GLASS_MENU,
      hud: "rounded-[1.375rem] border-transparent text-(--lc-glass-hud-ink) [--lc-glass-fill:var(--lc-glass-hud-fill)] [--lc-glass-shadow:var(--lc-glass-hud-shadow)] [--lc-glass-solid:var(--lc-glass-hud-solid)]"
    }.freeze

    GLASS_THICK =
      "max-md:[--lc-glass-fill:color-mix(in_oklab,var(--background)_90%,transparent)] " \
      "dark:max-md:[--lc-glass-fill:color-mix(in_oklab,var(--muted)_92%,transparent)]"

    def lc_glass_class(shape: :bar, thick: false, extra: nil)
      lc_tw("lc-glass", GLASS_SHAPES.fetch(shape.to_sym, GLASS_SHAPES[:bar]), (GLASS_THICK if thick), extra)
    end
  end
end
