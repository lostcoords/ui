module Lostcoords::Ui
  module GlassHelper
    # Menus lift further, and on phones go solid: they cover rows that look like their own
    # options, and some open where nothing blurs (the dock). Dark lifts to paper-3 to clear cards.
    GLASS_MENU = "[--glass-shadow:var(--glass-rim),var(--shadow-lg)] max-md:[--glass-fill:var(--paper)] dark:max-md:[--glass-fill:var(--paper-3)]"

    GLASS_SHAPES = {
      bar: "rounded-full border-(--glass-bar-edge)",
      panel: "rounded-3xl",
      disc: "rounded-full",
      menu: "rounded-3xl #{GLASS_MENU}",
      # A picker is a menu on desktop and a bottom sheet on phones, so its own CSS owns the corners.
      picker: GLASS_MENU,
      hud: "rounded-[1.375rem] border-transparent text-(--glass-hud-ink) [--glass-fill:var(--glass-hud-fill)] [--glass-shadow:var(--glass-hud-shadow)] [--glass-solid:var(--glass-hud-solid)]"
    }.freeze

    GLASS_THICK =
      "max-md:[--glass-fill:color-mix(in_oklab,var(--paper)_90%,transparent)] " \
      "dark:max-md:[--glass-fill:color-mix(in_oklab,var(--paper-2)_92%,transparent)]"

    def glass_class(shape: :bar, thick: false, extra: nil)
      tw("glass", GLASS_SHAPES.fetch(shape.to_sym, GLASS_SHAPES[:bar]), (GLASS_THICK if thick), extra)
    end
  end
end
