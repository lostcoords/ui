module Lostcoords::Ui
  module MenuHelper
    # FloatingPanel sets [data-open]; the caller picks the display.
    POPOVER_BASE =
      "row-menu__popover squircle popover-shell hidden absolute top-[calc(100%+--spacing(1))] end-0 overscroll-contain [&_form]:m-0"

    MENU_POPOVER_BASE =
      "data-open:flex flex-col gap-0.5 z-nav-popover p-2 " \
      "min-w-56 max-w-[calc(100vw-clamp(1rem,3vw,1.5rem)*2)] max-h-[min(24rem,70vh)] overflow-y-auto"

    MENU_POPOVER_ALIGN = {
      start: "start-0 end-auto",
      end: "",
      center: "start-1/2 end-auto -translate-x-1/2"
    }.freeze

    MENU_OPTION_BASE =
      "row-menu__item press [--press-scale:0.98] group/option grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-x-3 w-full " \
      "min-h-11 px-3 py-2 rounded-xl border-none bg-transparent text-start font-body text-[0.9375rem] font-medium text-ink " \
      "no-underline cursor-pointer transition-[background-color] duration-120 [--avatar-size:--spacing(7)] " \
      "hover:bg-paper-2 focus-visible:bg-paper-2 focus-visible:outline-none " \
      "disabled:text-ink-3 disabled:cursor-not-allowed disabled:hover:bg-transparent"

    MENU_OPTION_TONES = {
      default: "",
      danger: "text-danger hover:bg-danger-soft focus-visible:bg-danger-soft"
    }.freeze

    def popover_class(align: :end, extra: nil)
      glass_class(shape: :menu, extra: tw(POPOVER_BASE, MENU_POPOVER_ALIGN.fetch(align), extra))
    end

    def menu_popover_class(align: :end, extra: nil)
      popover_class(align: align, extra: tw(MENU_POPOVER_BASE, extra))
    end

    def menu_option_class(tone: :default, extra: nil)
      tw(MENU_OPTION_BASE, MENU_OPTION_TONES.fetch(tone), extra)
    end
  end
end
