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
      lc_glass_class(shape: :menu, extra: lc_tw(POPOVER_BASE, MENU_POPOVER_ALIGN.fetch(lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)), extra))
    end

    def lc_menu_popover_class(align: :end, extra: nil)
      lc_popover_class(align: align, extra: lc_tw(MENU_POPOVER_BASE, extra))
    end

    def lc_menu_option_class(tone: :default, extra: nil)
      lc_tw(MENU_OPTION_BASE, MENU_OPTION_TONES.fetch(lc_option!(:tone, tone, MENU_OPTION_TONES.keys)), extra)
    end

    def lc_menu(id:, label: lc_t("lostcoords.ui.menu.label"), align: :end, **attributes, &block)
      align = lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)
      lc_render_panel(id, label, nil, "lc-menu", "menu", lc_menu_popover_class(align: align), lc_attributes({ data: { slot: "menu" } }, attributes), &block)
    end

    def lc_popover(id:, label: lc_t("lostcoords.ui.popover.trigger"), title: nil, align: :end, trigger_variant: :secondary, **attributes, &block)
      title = title.presence
      align = lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)
      classes = lc_popover_class(align: align, extra: "data-open:flex flex-col gap-content p-inset z-(--lc-z-popover) min-w-64 max-w-[calc(100vw-2rem)]")
      lc_render_panel(id, label, title, "lc-popover", "dialog", classes, lc_attributes({ data: { slot: "popover" } }, attributes), trigger_variant: trigger_variant, &block)
    end

    def lc_menu_option(label = nil, href: nil, tone: :default, **attributes, &block)
      tone = lc_option!(:tone, tone, MENU_OPTION_TONES.keys)
      content = tag.span(block ? capture(&block) : label, class: "col-span-3")
      defaults = { class: lc_menu_option_class(tone: tone), role: "menuitem", data: { slot: "menu-item", action: "click->lc-menu#close" } }
      if href
        raise ArgumentError, "Links cannot be disabled; use a menu button instead" if attributes[:disabled] || attributes["disabled"]

        tag.a(content, **lc_attributes(defaults.merge(href: href), attributes))
      else
        tag.button(content, **lc_attributes(defaults.merge(type: "button"), attributes))
      end
    end

    private
    def lc_render_panel(id, label, title, controller, role, classes, attributes, trigger_variant: :secondary, &block)
      lc_label!(id, :id)
      lc_label!(label, :label)
      required = { id: id, role: role, aria: { labelledby: "#{id}-#{title ? 'title' : 'trigger'}" }, data: { "#{controller}_target" => "popover" } }
      required[:tabindex] = -1 if role == "dialog"
      merged = lc_attributes({ class: classes }, attributes, required)
      render "lostcoords/ui/components/lc_floating_panel", id: id, label: label, title: title, controller: controller, role: role, trigger_variant: trigger_variant, attributes: merged, content: (capture(&block) if block)
    end
  end
end
