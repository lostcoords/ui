module Lostcoords::Ui
  module MenuHelper
    # FloatingPanel sets [data-open]; the caller picks the display.
    POPOVER_BASE =
      "lc-menu__popover lc-squircle lc-popover-shell hidden absolute top-[calc(100%+--spacing(1))] end-0 overscroll-contain [&_form]:m-0"

    MENU_POPOVER_BASE =
      "data-open:flex flex-col gap-px z-(--lc-z-popover) p-related " \
      "min-w-56 max-w-[calc(100vw-clamp(1rem,3vw,1.5rem)*2)] max-h-[min(24rem,70vh)] overflow-y-auto"

    MENU_POPOVER_ALIGN = {
      start: "start-0 end-auto",
      end: "",
      center: "start-1/2 end-auto -translate-x-1/2"
    }.freeze

    MENU_OPTION_BASE =
      "lc-menu__item lc-press [--lc-press-scale:0.98] group/option grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-x-3 w-full " \
      "min-h-control-md px-3 py-1.5 rounded-2xl lc-squircle border-none bg-transparent text-start font-sans text-label text-foreground " \
      "no-underline cursor-pointer transition-[background-color] duration-120 [--lc-avatar-size:--spacing(7)] " \
      "hover:bg-accent focus-visible:bg-accent focus-visible:outline-none " \
      "disabled:text-muted-foreground disabled:cursor-not-allowed disabled:hover:bg-transparent"

    MENU_OPTION_TONES = {
      default: "",
      destructive: "text-destructive hover:bg-destructive-soft focus-visible:bg-destructive-soft"
    }.freeze

    def lc_popover_class(align: :end, extra: nil)
      lc_glass_class(shape: :menu, extra: lc_tw(POPOVER_BASE, MENU_POPOVER_ALIGN.fetch(align), extra))
    end

    def lc_menu_popover_class(align: :end, extra: nil)
      lc_popover_class(align: align, extra: lc_tw(MENU_POPOVER_BASE, extra))
    end

    def lc_menu_option_class(tone: :default, extra: nil)
      lc_tw(MENU_OPTION_BASE, MENU_OPTION_TONES.fetch(tone), extra)
    end
  end
end
