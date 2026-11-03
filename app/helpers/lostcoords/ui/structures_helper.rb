module Lostcoords::Ui
  module StructuresHelper
    INPUT_TYPES = %i[text search email password tel url number date time datetime-local month week].freeze
    SHEET_DETENTS = [ "fit", "medium large", "large" ].freeze

    def lc_input(name: nil, value: nil, type: :text, size: :md, **attributes)
      type = lc_option!(:type, type, INPUT_TYPES)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      tag.input(**lc_attributes({ type: type, name: name, value: value, class: lc_input_class(size: size), data: { slot: "input" } }, attributes))
    end

    def lc_textarea(content = nil, name: nil, **attributes, &block)
      tag.textarea(block ? capture(&block) : content, **lc_attributes({ name: name, class: lc_textarea_class, data: { slot: "textarea" } }, attributes))
    end

    def lc_select(options = nil, name: nil, selected: nil, size: :md, **attributes, &block)
      size = lc_option!(:size, size, TailwindHelper::CONTROL_SIZES.keys)
      content = block ? capture(&block) : options_for_select(options || [], selected)
      tag.select(content, **lc_attributes({ name: name, class: lc_select_class(size: size), data: { slot: "select" } }, attributes))
    end

    # Yields the control's attributes; splat them into the control with `**field`. error: takes a
    # message or a list of messages, such as `record.errors.full_messages_for(:name)`.
    def lc_field(label:, id:, hint: nil, error: nil, **attributes, &block)
      lc_label!(label, :label)
      lc_label!(id, :id)
      errors = Array(error).compact_blank
      descriptions = [ ("#{id}-hint" if hint.present?), ("#{id}-error" if errors.any?) ].compact
      control = { id: id, aria: { describedby: descriptions.presence&.join(" "), invalid: (true if errors.any?) } }
      tag.div(**lc_attributes({ class: lc_field_class, data: { slot: "field", invalid: (true if errors.any?) } }, attributes)) do
        safe_join([
          tag.label(label, for: id, class: lc_field_label_class, data: { slot: "field-label" }),
          (capture(Parts::Field.new(self, id, control), &block) if block),
          *lc_field_messages(id, hint, errors)
        ].compact)
      end
    end

    def lc_toggle_group(label:, name: nil, value: nil, **attributes, &block)
      lc_label!(label, :label)
      defaults = { class: lc_toggle_group_class, role: "group", aria: { label: label }, data: { slot: "toggle-group", controller: "lc-selection", action: "click->lc-selection#select keydown->lc-selection#navigate", lc_selection_value_value: value } }
      tag.div(**lc_attributes(lc_attributes(defaults, attributes), { role: "group", aria: { label: label } })) do
        safe_join([ (hidden_field_tag(name, value, data: { lc_selection_target: "input" }) if name), (capture(&block) if block) ].compact)
      end
    end

    def lc_toggle_group_item(label = nil, value: nil, selected: false, **attributes, &block)
      value ||= label
      lc_label!(value, :value)
      defaults = { class: lc_toggle_group_item_class, type: "button", aria: { pressed: selected }, data: { slot: "toggle-group-item", lc_selection_target: "option", value: value } }
      required = { type: "button", data: { lc_selection_target: "option", value: value } }
      tag.button(block ? capture(&block) : label, **lc_attributes(lc_attributes(defaults, attributes), required))
    end

    def lc_toggle(label = nil, active: false, ghost: false, size: :md, **attributes, &block)
      raise ArgumentError, "Use lc_button_link_to for navigation" if attributes.key?(:href) || attributes.key?("href")
      defaults = { class: lc_toggle_class(ghost: ghost, size: size), type: "button", aria: { pressed: active }, data: { slot: "toggle", controller: "lc-toggle", action: "click->lc-toggle#toggle" } }
      tag.button(block ? capture(&block) : label, **lc_attributes(defaults, attributes).merge(type: "button"))
    end

    # Yields a builder with footer and close parts.
    def lc_dialog(id:, title:, description: nil, trigger: lc_t("lostcoords.ui.dialog.trigger"), kind: :modal, detents: "fit", **attributes, &block)
      kind = lc_option!(:kind, kind, DialogHelper::DIALOGS.keys)
      detents = detents.to_s
      raise ArgumentError, "detents must be one of #{SHEET_DETENTS.join(', ')}" unless SHEET_DETENTS.include?(detents)
      defaults = { class: lc_dialog_class(kind), aria: { describedby: ("#{id}-description" if description.present?) }, data: lc_sheet_data({ slot: "dialog" }, detents: detents) }
      lc_render_dialog(id, title, description, trigger, defaults, attributes, &block)
    end

    def lc_menu(id:, label: lc_t("lostcoords.ui.menu.label"), align: :end, **attributes, &block)
      align = lc_option!(:align, align, MenuHelper::MENU_POPOVER_ALIGN.keys)
      lc_render_panel(id, label, nil, "lc-menu", "menu", lc_menu_popover_class(align: align), lc_attributes({ data: { slot: "menu" } }, attributes), &block)
    end

    def lc_popover(id:, label: lc_t("lostcoords.ui.popover.trigger"), title: nil, align: :end, trigger_variant: :secondary, **attributes, &block)
      title = title.presence
      align = lc_option!(:align, align, MenuHelper::MENU_POPOVER_ALIGN.keys)
      classes = lc_popover_class(align: align, extra: "data-open:flex flex-col gap-content p-inset z-(--lc-z-popover) min-w-64 max-w-[calc(100vw-2rem)]")
      lc_render_panel(id, label, title, "lc-popover", "dialog", classes, lc_attributes({ data: { slot: "popover" } }, attributes), trigger_variant: trigger_variant, &block)
    end

    def lc_menu_option(label = nil, href: nil, tone: :default, **attributes, &block)
      tone = lc_option!(:tone, tone, MenuHelper::MENU_OPTION_TONES.keys)
      content = tag.span(block ? capture(&block) : label, class: "col-span-3")
      defaults = { class: lc_menu_option_class(tone: tone), role: "menuitem", data: { slot: "menu-item", action: "click->lc-menu#close" } }
      if href
        raise ArgumentError, "Links cannot be disabled; use a menu button instead" if attributes[:disabled] || attributes["disabled"]

        tag.a(content, **lc_attributes(defaults.merge(href: href), attributes))
      else
        tag.button(content, **lc_attributes(defaults.merge(type: "button"), attributes))
      end
    end

    def lc_toast(message = nil, tone: :success, timeout: 4000, **attributes, &block)
      tone = lc_option!(:tone, tone, FeedbackHelper::ALERT_ICONS.keys)
      raise ArgumentError, "timeout must be a nonnegative integer" unless timeout.is_a?(Integer) && timeout >= 0

      defaults = { class: lc_glass_class(shape: :hud, extra: "flex items-center gap-related px-content py-heading text-label font-semibold transition-opacity data-leaving:opacity-0"), role: tone == :destructive ? "alert" : "status", data: { slot: "toast", tone: tone, controller: "lc-toast", action: "click->lc-toast#dismiss", lc_toast_timeout_value: timeout } }
      tag.div(**lc_attributes(defaults, attributes)) do
        safe_join([ lc_alert_icon(tone: tone), tag.span(block ? capture(&block) : message) ])
      end
    end

    def lc_collapsible(title:, open: false, **attributes, &block)
      lc_label!(title, :title)
      defaults = { class: lc_card_class(extra: "lc-collapsible"), open: open, data: { slot: "collapsible", controller: "lc-collapsible", action: "click->lc-collapsible#toggle" } }
      render "lostcoords/ui/components/lc_collapsible", title: title, attributes: lc_attributes(defaults, attributes), content: (capture(&block) if block)
    end

    def lc_emoji_picker(form:, field:, label:, catalog_url:, value: nil, quick: [], recent: [], recent_scope: nil, auto_submit: false, **attributes)
      lc_label!(label, :label)
      lc_label!(catalog_url, :catalog_url)
      render "lostcoords/ui/components/emoji_picker", form: form, field: field, label: label, catalog_url: catalog_url, value: value, quick: quick, recent: recent, recent_scope: recent_scope, auto_submit: auto_submit, attributes: attributes
    end

    private
      # The hint and error paragraphs under a field or choice group. With an id, controls can point
      # aria-describedby at them.
      def lc_field_messages(id, hint, errors)
        [
          (tag.p(hint, id: ("#{id}-hint" if id), class: "m-0 text-small text-muted-foreground", data: { slot: "field-description" }) if hint.present?),
          (tag.p(safe_join(errors, tag.br), id: ("#{id}-error" if id), class: "m-0 text-small text-destructive", role: "alert", data: { slot: "field-error" }) if errors.any?)
        ].compact
      end


    def lc_label!(value, name)
      raise ArgumentError, "#{name} must not be blank" if value.blank?
    end

    def lc_render_dialog(id, title, description, trigger, defaults, attributes, &block)
      lc_label!(id, :id)
      lc_label!(title, :title)
      lc_label!(trigger, :trigger)
      required = { id: id, aria: { labelledby: "#{id}-title" }, data: (defaults[:data] || {}).merge(lc_dialog_target: "dialog") }
      merged = lc_attributes(lc_attributes(defaults, attributes), required)
      render "lostcoords/ui/components/lc_dialog", id: id, title: title, description: description, trigger: trigger, attributes: merged, content: (capture(Parts::Dialog.new(self, id), &block) if block)
    end

    def lc_render_panel(id, label, title, controller, role, classes, attributes, trigger_variant: :secondary, &block)
      lc_label!(id, :id)
      lc_label!(label, :label)
      required = { id: id, role: role, aria: { labelledby: "#{id}-#{title ? 'title' : 'trigger'}" }, data: { "#{controller}_target" => "popover" } }
      required[:tabindex] = -1 if role == "dialog"
      merged = lc_attributes(lc_attributes({ class: classes }, attributes), required)
      render "lostcoords/ui/components/lc_floating_panel", id: id, label: label, title: title, controller: controller, role: role, trigger_variant: trigger_variant, attributes: merged, content: (capture(&block) if block)
    end
  end
end
