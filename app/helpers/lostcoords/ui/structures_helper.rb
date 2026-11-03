module Lostcoords::Ui
  module StructuresHelper
    INPUT_TYPES = %i[text search email password tel url number date time datetime-local month week].freeze
    SHEET_DETENTS = [ "fit", "medium large", "large" ].freeze

    def ui_input(name: nil, value: nil, type: :text, size: :base, **attributes)
      type = ui_option!(:type, type, INPUT_TYPES)
      size = ui_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      tag.input(**ui_attributes({ type: type, name: name, value: value, class: input_class(size: size) }, attributes))
    end

    def ui_textarea(content = nil, name: nil, **attributes, &block)
      tag.textarea(block ? capture(&block) : content, **ui_attributes({ name: name, class: textarea_class }, attributes))
    end

    def ui_select(options = nil, name: nil, selected: nil, size: :base, **attributes, &block)
      size = ui_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      content = block ? capture(&block) : options_for_select(options || [], selected)
      tag.select(content, **ui_attributes({ name: name, class: select_class(size: size) }, attributes))
    end

    def ui_field(label:, id:, hint: nil, error: nil, **attributes, &block)
      ui_label!(label, :label)
      ui_label!(id, :id)
      descriptions = [ ("#{id}-hint" if hint.present?), ("#{id}-error" if error.present?) ].compact
      control = { id: id, aria: { describedby: descriptions.presence&.join(" "), invalid: (true if error.present?) } }
      tag.div(**ui_attributes({ class: field_class }, attributes)) do
        safe_join([
          tag.label(label, for: id, class: field_label_class),
          (capture(control, &block) if block),
          (tag.p(hint, id: "#{id}-hint", class: "text-sm text-ink-3") if hint.present?),
          (tag.p(error, id: "#{id}-error", class: "text-sm text-berry", role: "alert") if error.present?)
        ].compact)
      end
    end

    def ui_form_actions(**attributes, &block)
      tag.div(**ui_attributes({ class: form_actions_class }, attributes), &block)
    end

    def ui_segmented(label:, name: nil, value: nil, **attributes, &block)
      ui_label!(label, :label)
      defaults = { class: segmented_class, role: "group", aria: { label: label }, data: { controller: "ui-selection", action: "click->ui-selection#select keydown->ui-selection#navigate", ui_selection_value_value: value } }
      tag.div(**ui_attributes(ui_attributes(defaults, attributes), { role: "group", aria: { label: label } })) do
        safe_join([ (hidden_field_tag(name, value, data: { ui_selection_target: "input" }) if name), (capture(&block) if block) ].compact)
      end
    end

    def ui_segmented_tab(label = nil, value: nil, selected: false, **attributes, &block)
      value ||= label
      ui_label!(value, :value)
      defaults = { class: segmented_tab_class, type: "button", aria: { pressed: selected }, data: { ui_selection_target: "option", value: value } }
      required = { type: "button", data: { ui_selection_target: "option", value: value } }
      tag.button(block ? capture(&block) : label, **ui_attributes(ui_attributes(defaults, attributes), required))
    end

    def ui_pill(label = nil, active: false, ghost: false, size: :base, href: nil, **attributes, &block)
      size = ui_option!(:size, size, %i[sm base lg])
      content = block ? capture(&block) : label
      defaults = { class: pill_class(ghost: ghost, size: size) }
      if href
        raise ArgumentError, "Links cannot be disabled; use a pill button instead" if attributes[:disabled] || attributes["disabled"]

        tag.a(content, **ui_attributes(defaults.merge(href: href, aria: { current: ("page" if active) }), attributes))
      else
        defaults.merge!(type: "button", aria: { pressed: active }, data: { controller: "ui-toggle", action: "click->ui-toggle#toggle" })
        tag.button(content, **ui_attributes(defaults, attributes).merge(type: "button"))
      end
    end

    def ui_pill_row(**attributes, &block)
      tag.div(**ui_attributes({ class: pill_row_class }, attributes), &block)
    end

    def ui_dialog(id:, title:, trigger: "Open dialog", kind: :modal, **attributes, &block)
      kind = ui_option!(:kind, kind, DialogHelper::DIALOGS.keys)
      ui_render_dialog(id, title, trigger, { class: dialog_class(kind), data: sheet_data }, attributes, &block)
    end

    def ui_sheet(id:, title:, trigger: "Open sheet", detents: "fit", **attributes, &block)
      detents = detents.to_s
      raise ArgumentError, "detents must be one of #{SHEET_DETENTS.join(', ')}" unless SHEET_DETENTS.include?(detents)

      defaults = { class: dialog_class, data: sheet_data({}, detents: detents) }
      ui_render_dialog(id, title, trigger, defaults, attributes, &block)
    end

    def ui_menu(id:, label: "Actions", align: :end, **attributes, &block)
      align = ui_option!(:align, align, MenuHelper::MENU_POPOVER_ALIGN.keys)
      ui_render_panel(id, label, nil, "row-menu", "menu", menu_popover_class(align: align), attributes, &block)
    end

    def ui_popover(id:, label: "Open popover", title: nil, align: :end, **attributes, &block)
      title = title.presence
      align = ui_option!(:align, align, MenuHelper::MENU_POPOVER_ALIGN.keys)
      classes = popover_class(align: align, extra: "data-open:flex flex-col gap-4 p-5 z-nav-popover min-w-64 max-w-[calc(100vw-2rem)]")
      ui_render_panel(id, label, title, "ui-popover", "dialog", classes, attributes, &block)
    end

    def ui_menu_option(label = nil, href: nil, tone: :default, **attributes, &block)
      tone = ui_option!(:tone, tone, MenuHelper::MENU_OPTION_TONES.keys)
      content = tag.span(block ? capture(&block) : label, class: "col-span-3")
      defaults = { class: menu_option_class(tone: tone), role: "menuitem", data: { action: "click->row-menu#close" } }
      if href
        raise ArgumentError, "Links cannot be disabled; use a menu button instead" if attributes[:disabled] || attributes["disabled"]

        tag.a(content, **ui_attributes(defaults.merge(href: href), attributes))
      else
        tag.button(content, **ui_attributes(defaults.merge(type: "button"), attributes))
      end
    end

    def ui_toast(message = nil, tone: :notice, timeout: 4000, **attributes, &block)
      tone = ui_option!(:tone, tone, FormHelper::FORM_ALERT_ICONS.keys)
      raise ArgumentError, "timeout must be a nonnegative integer" unless timeout.is_a?(Integer) && timeout >= 0

      defaults = { class: glass_class(shape: :hud, extra: "flex items-center gap-2 px-4 py-3 text-sm font-semibold transition-opacity data-leaving:opacity-0"), role: tone == :error ? "alert" : "status", data: { controller: "toast", action: "click->toast#dismiss", toast_timeout_value: timeout } }
      tag.div(**ui_attributes(defaults, attributes)) do
        safe_join([ form_alert_icon(tone: tone), tag.span(block ? capture(&block) : message) ])
      end
    end

    def ui_disclosure(title:, open: false, **attributes, &block)
      ui_label!(title, :title)
      defaults = { class: card_class(extra: "disclosure-animated"), open: open, data: { controller: "disclosure", action: "click->disclosure#toggle" } }
      render "lostcoords/ui/components/ui_disclosure", title: title, attributes: ui_attributes(defaults, attributes), content: (capture(&block) if block)
    end

    def ui_emoji_picker(form:, field:, label:, catalog_url:, value: nil, quick: [], recent: [], recent_scope: nil, auto_submit: false, **attributes)
      ui_label!(label, :label)
      ui_label!(catalog_url, :catalog_url)
      render "lostcoords/ui/components/emoji_picker", form: form, field: field, label: label, catalog_url: catalog_url, value: value, quick: quick, recent: recent, recent_scope: recent_scope, auto_submit: auto_submit, attributes: attributes
    end

    private

    def ui_label!(value, name)
      raise ArgumentError, "#{name} must not be blank" if value.blank?
    end

    def ui_render_dialog(id, title, trigger, defaults, attributes, &block)
      ui_label!(id, :id)
      ui_label!(title, :title)
      ui_label!(trigger, :trigger)
      required = { id: id, aria: { labelledby: "#{id}-title" }, data: (defaults[:data] || {}).merge(modal_target: "dialog") }
      merged = ui_attributes(ui_attributes(defaults, attributes), required)
      render "lostcoords/ui/components/ui_dialog", id: id, title: title, trigger: trigger, attributes: merged, content: (capture(&block) if block)
    end

    def ui_render_panel(id, label, title, controller, role, classes, attributes, &block)
      ui_label!(id, :id)
      ui_label!(label, :label)
      required = { id: id, role: role, aria: { labelledby: "#{id}-#{title ? 'title' : 'trigger'}" }, data: { "#{controller}_target" => "popover" } }
      required[:tabindex] = -1 if role == "dialog"
      merged = ui_attributes(ui_attributes({ class: classes }, attributes), required)
      render "lostcoords/ui/components/ui_floating_panel", id: id, label: label, title: title, controller: controller, role: role, attributes: merged, content: (capture(&block) if block)
    end
  end
end
