module Lostcoords::Ui
  module MenuHelper
    # FloatingPanel sets [data-open]; the caller picks the display.
    POPOVER_BASE =
      "lc-menu__popover lc-squircle lc-popover-shell hidden absolute top-[calc(100%+--spacing(1))] end-0 overscroll-contain [&_form]:m-0"

    MENU_POPOVER_BASE =
      "data-open:grid grid-cols-[auto_minmax(0,1fr)_auto] content-start gap-y-px [&>*]:col-span-full " \
      "[&_[data-slot=menu-item]]:grid-cols-subgrid z-(--lc-z-popover) p-related " \
      "min-w-56 max-w-[calc(100vw-clamp(1rem,3vw,1.5rem)*2)] max-h-[min(24rem,70vh)] overflow-y-auto"

    MENU_POPOVER_ALIGN = {
      start: "start-0 end-auto",
      end: "",
      center: "start-1/2 end-auto -translate-x-1/2"
    }.freeze

    MENU_OPTION_BASE =
      "lc-menu__item lc-press [--lc-press-scale:0.98] group/option grid col-span-full grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-x-3 w-full " \
      "min-h-control-md px-3 py-1.5 rounded-2xl lc-squircle border-none bg-transparent text-start font-sans text-label text-foreground " \
      "no-underline cursor-pointer transition-[background-color] duration-120 [--lc-avatar-size:--spacing(7)] " \
      "hover:bg-accent focus-visible:bg-accent focus-visible:outline-none " \
      "disabled:text-muted-foreground disabled:cursor-not-allowed disabled:hover:bg-transparent"

    MENU_OPTION_TONES = {
      default: "",
      destructive: "text-destructive hover:bg-destructive-soft focus-visible:bg-destructive-soft"
    }.freeze

    MENU_OPTION_LEADING = "col-start-1 me-3 grid min-w-5 place-items-center text-lg leading-none"
    MENU_OPTION_ICON = "size-5 text-muted-foreground group-aria-checked/option:text-primary group-data-[tone=destructive]/option:text-current"
    MENU_OPTION_LABEL = "col-start-2 grid min-w-0 group-aria-checked/option:font-semibold"
    MENU_OPTION_HINT = "text-caption font-normal text-muted-foreground"
    MENU_OPTION_CHECK = "col-start-3 ms-3 size-4 text-primary invisible group-aria-checked/option:visible"

    MENU_TRIGGERS = %i[button icon].freeze

    MENU_GROUP_BASE = "col-span-full grid grid-cols-subgrid gap-y-px"
    MENU_GROUP_LABEL = "col-span-full px-3 pt-2 pb-1"

    def lc_popover_class(align: :end, extra: nil)
      lc_glass_class(shape: :menu, extra: lc_tw(POPOVER_BASE, MENU_POPOVER_ALIGN.fetch(lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)), extra))
    end

    def lc_menu_popover_class(align: :end, extra: nil)
      lc_popover_class(align: align, extra: lc_tw(MENU_POPOVER_BASE, extra))
    end

    def lc_menu_option_class(tone: :default, extra: nil)
      lc_tw(MENU_OPTION_BASE, MENU_OPTION_TONES.fetch(lc_option!(:tone, tone, MENU_OPTION_TONES.keys)), extra)
    end

    # trigger: :icon renders a quiet icon button named by label; rendered HTML becomes the content
    # of a custom trigger, also named by label.
    def lc_menu(id:, label: lc_t("lostcoords.ui.menu.label"), align: :end, trigger: :button, icon: "ellipsis-vertical", trigger_attributes: {}, wrapper_attributes: {}, **attributes, &block)
      align = lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)
      default_trigger = ->(wiring) { lc_panel_trigger(label, trigger, icon, :secondary, wiring) } unless trigger == false
      lc_render_panel(id, label, nil, "lc-menu", "menu", lc_menu_popover_class(align: align), lc_attributes({ data: { slot: "menu" } }, attributes), default_trigger, trigger_attributes, wrapper_attributes, &block)
    end

    # Takes the same trigger options as lc_menu, including trigger: false.
    def lc_popover(id:, label: lc_t("lostcoords.ui.popover.trigger"), title: nil, align: :end, trigger_variant: :secondary, trigger: :button, icon: "ellipsis-vertical", trigger_attributes: {}, wrapper_attributes: {}, **attributes, &block)
      title = title.presence
      align = lc_option!(:align, align, MENU_POPOVER_ALIGN.keys)
      default_trigger = ->(wiring) { lc_panel_trigger(label, trigger, icon, trigger_variant, wiring) } unless trigger == false
      classes = lc_popover_class(align: align, extra: "data-open:flex flex-col gap-content p-inset z-(--lc-z-popover) min-w-64 max-w-[calc(100vw-2rem)]")
      lc_render_panel(id, label, title, "lc-popover", "dialog", classes, lc_attributes({ data: { slot: "popover" } }, attributes), default_trigger, trigger_attributes, wrapper_attributes, &block)
    end

    # icon: names a leading Heroicon; leading: takes other rendered content, such as an avatar, and is
    # hidden from assistive technology so the label stays the name. checked: true or false makes a
    # menuitemradio with a check mark. checkbox: true makes a menuitemcheckbox that flips on click and
    # leaves the menu open. method: renders a button_to form for href.
    def lc_menu_option(label = nil, href: nil, tone: :default, icon: nil, leading: nil, hint: nil, checked: nil, checkbox: false, method: nil, params: {}, form: {}, **attributes, &block)
      tone = lc_option!(:tone, tone, MENU_OPTION_TONES.keys)
      raise ArgumentError, "Pass icon: or leading:, not both" if icon && leading
      raise ArgumentError, "checked: must be true, false or nil" unless [ true, false, nil ].include?(checked)
      raise ArgumentError, "method: needs an href:" if method && !href
      raise ArgumentError, "checkbox: true renders a button; drop href:" if checkbox && href
      checked = !!checked if checkbox

      leading = lc_icon(icon, options: { class: MENU_OPTION_ICON }) if icon
      text = block ? capture(&block) : label
      content = safe_join([
        (tag.span(leading, class: MENU_OPTION_LEADING, aria: { hidden: true }, data: { slot: "menu-item-leading" }) if leading),
        tag.span(hint ? safe_join([ tag.span(text), tag.span(hint, class: MENU_OPTION_HINT, data: { slot: "menu-item-hint" }) ]) : text, class: MENU_OPTION_LABEL),
        (lc_icon("check", variant: :mini, options: { class: MENU_OPTION_CHECK, "aria-hidden": true }) unless checked.nil?)
      ])
      role = checkbox ? "menuitemcheckbox" : (checked.nil? ? "menuitem" : "menuitemradio")
      defaults = { class: lc_menu_option_class(tone: tone, extra: "gap-x-0"), role: role, data: { slot: "menu-item", tone: tone, action: checkbox ? "click->lc-menu#check" : "click->lc-menu#close" } }
      defaults[:aria] = { checked: checked } unless checked.nil?

      if method
        button_to(content, href, **lc_attributes(defaults, attributes), method: method, params: params, form: lc_attributes({ class: "contents" }, form))
      elsif href
        raise ArgumentError, "Links cannot be disabled; use a menu button instead" if attributes[:disabled] || attributes["disabled"]

        tag.a(content, **lc_attributes(defaults.merge(href: href), attributes))
      else
        tag.button(content, **lc_attributes(defaults.merge(type: "button"), attributes))
      end
    end

    # A labelled run of options inside a menu panel. Its options stay on the menu's columns.
    def lc_menu_group(label, id:, **attributes, &block)
      lc_label!(label, :label)
      lc_label!(id, :id)
      heading = lc_text(label, size: :eyebrow, tone: :muted, as: :div, id: "#{id}-label", class: MENU_GROUP_LABEL, role: "presentation")
      tag.div(safe_join([ heading, capture(&block) ]), **lc_attributes({ class: MENU_GROUP_BASE, data: { slot: "menu-group" } }, attributes, { id: id, role: "group", aria: { labelledby: "#{id}-label" } }))
    end

    private
    def lc_panel_trigger(label, trigger, icon, variant, attributes)
      custom = trigger.is_a?(String) && trigger.html_safe?
      kind = custom ? :custom : lc_option!(:trigger, trigger, MENU_TRIGGERS)
      case kind
      when :custom, :icon
        content = custom ? trigger : lc_icon(icon, options: { "aria-hidden": true })
        icon_button = { type: "button", class: lc_icon_button_class(shape: :circle, size: :md, extra: ButtonHelper::ICON_BUTTON_QUIET), aria: { label: label }, data: { slot: "icon-button" } }
        tag.button(content, **lc_attributes(icon_button, attributes))
      else
        lc_button(label, variant: variant, **attributes)
      end
    end

    # The block runs before the default trigger renders, so a menu.trigger part can replace it.
    # trigger: false renders only the panel, for a caller that hosts the controller on an ancestor
    # and wires its own triggers.
    def lc_render_panel(id, label, title, controller, role, classes, attributes, default_trigger, trigger_attributes, wrapper_attributes, &block)
      lc_label!(id, :id)
      lc_label!(label, :label)
      standalone = default_trigger.nil?
      raise ArgumentError, "trigger: false renders no trigger or wrapper" if standalone && (trigger_attributes.present? || wrapper_attributes.present?)

      wiring = { id: "#{id}-trigger", aria: { haspopup: role, expanded: false, controls: id }, data: { "#{controller}_target" => "trigger", action: "#{controller}#toggle" } }
      parts = Parts::Panel.new(self, wiring)
      content = capture(parts, &block) if block
      trigger = parts.rendered_trigger || default_trigger.call(lc_attributes(trigger_attributes, wiring)) unless standalone
      name = if title then { labelledby: "#{id}-title" } elsif standalone then { label: label } else { labelledby: "#{id}-trigger" } end
      required = { id: id, role: role, aria: name, data: { "#{controller}_target" => "popover" } }
      required[:tabindex] = -1 if role == "dialog"
      merged = lc_attributes({ class: classes }, attributes, required)
      wrapper = lc_attributes({ class: "relative inline-flex" }, wrapper_attributes, { data: { controller: controller } }) unless standalone
      render "lostcoords/ui/components/lc_floating_panel", id: id, title: title, wrapper: wrapper, trigger: trigger, attributes: merged, content: content
    end
  end
end
