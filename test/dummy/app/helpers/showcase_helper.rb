module ShowcaseHelper
  def showcase_builders(section)
    Lostcoords::Ui::Builders.all.select { |builder| section.builders.include?(builder.name) }
  end

  def showcase_title(example, index)
    return example.title if example.title

    if example.specimen == :value
      return example.calls.values.first[/\A\w+/].delete_prefix("emoji_picker_").humanize
    end
    if example.specimen == :card
      call = example.calls.values.first
      return "Surface" if call.start_with?("card_surface_class")
      return "Interactive" if call.include?("interactive: true")
    end
    return "Compact" if example.calls.values.first.include?("compact: true")

    common = example.calls.values.map { |item| item.scan(/(variant|shape|tone|padding|size): :([\w]+)/) }.reduce { |memo, options| memo & options }
    options = common.map { |key, value| key == "size" ? { "sm" => "Small", "base" => "Default", "lg" => "Large", "nav" => "Navigation" }.fetch(value, value.humanize) : value.humanize }
    return options.join(" · ") if options.any?

    { invalid_field: "Validation", sort_menu: "Text trigger", pill_toggles: "Toggle buttons", pill_links: "Navigation", segmented_tabs: "Tabs and toggles", avatar_stack: "Grouped", confirm_dialog: "Confirmation", context_dialog: "From a menu", modal_dialog: "Modal", form_actions: "Form actions", empty_state: "Empty state", html: "Partial", value: "Helper" }.fetch(example.specimen, index.zero? ? "Default" : "Example #{index + 1}")
  end

  def showcase_source(example, id:)
    source = showcase_erb(example, id:)
    source.include?("demo#") ? "<div data-controller=\"demo\">\n#{source}\n</div>" : source
  end

  def showcase_erb(example, id:)
    expression = example.calls.values.first
    if example.specimen == :html || example.specimen == :value
      if expression.include?("showcase_form")
        return "<%= fields_for :project do |form| %>\n  <%= #{expression.sub('showcase_form', 'form')} %>\n<% end %>"
      end
      return "<%= #{expression} %>"
    end

    source = Rails.root.join("app/views/showcase/specimens/_#{example.specimen}.html.erb").read
    if (loop_body = source[/\A<% classes\.each(?:_value)? do \|[^|]+\| %>\n(.*)\n<% end %>\s*\z/m, 1])
      return example.calls.map do |key, call|
        loop_body.gsub(/<%= value %>/, "<%= #{call} %>")
          .gsub(/<%= (?:tone|size)\.to_s\.capitalize %>/, key.to_s.humanize)
          .gsub(/^  /, "")
      end.join("\n")
    end

    source.gsub(/classes\[:(\w+)\]/) { example.calls.fetch(Regexp.last_match(1).to_sym) }
      .gsub("<%= id %>", id).gsub('#{id}', id).strip
  end

  def showcase_parameters(builder)
    parameter_rows(builder.signature)
  end

  def parameter_rows(signature)
    node = Prism.parse("def #{signature}; end").value.statements.body.first.parameters
    return [] unless node

    (node.requireds + node.optionals + node.posts + node.keywords + [ node.rest, node.keyword_rest, node.block ].compact).map do |parameter|
      [ parameter.name, parameter.respond_to?(:value) ? parameter.value.slice : "Required" ]
    end
  end

  def showcase_choices(builder, parameter)
    ui = Lostcoords::Ui
    choices = {
      button_class: { variant: ui::ButtonHelper::BUTTON_VARIANTS, size: ui::ButtonHelper::BUTTON_SIZES },
      icon_button_class: { shape: ui::ButtonHelper::ICON_BUTTON_SHAPES, size: ui::ButtonHelper::ICON_BUTTON_SIZES },
      badge_class: { tone: ui::BadgeHelper::BADGE_TONES },
      status_pill_class: { tone: ui::BadgeHelper::STATUS_PILL_TONES },
      avatar_class: { size: ui::BadgeHelper::AVATAR_SIZES },
      icon_badge_class: { size: ui::BadgeHelper::ICON_BADGE_SIZES },
      icon_medallion_class: { size: ui::BadgeHelper::ICON_MEDALLION_SIZES, tone: ui::BadgeHelper::ICON_MEDALLION_TONES },
      pill_class: { size: ui::ButtonHelper::BUTTON_SIZES },
      input_class: { size: ui::TailwindHelper::CONTROL_SIZES },
      select_class: { size: ui::TailwindHelper::CONTROL_SIZES },
      dropdown_trigger_class: { size: ui::TailwindHelper::CONTROL_SIZES },
      form_card_class: { padding: ui::CardHelper::FORM_CARD_PADDINGS },
      dialog_class: { kind: ui::DialogHelper::DIALOGS },
      form_alert_icon: { tone: ui::FormHelper::FORM_ALERT_ICONS },
      spinner_class: { size: ui::FeedbackHelper::SPINNER_SIZES },
      glass_class: { shape: ui::GlassHelper::GLASS_SHAPES },
      popover_class: { align: ui::MenuHelper::MENU_POPOVER_ALIGN },
      menu_popover_class: { align: ui::MenuHelper::MENU_POPOVER_ALIGN },
      menu_option_class: { tone: ui::MenuHelper::MENU_OPTION_TONES }
    }.dig(builder.name, parameter)
    if builder.name == :sheet_data && parameter == :detents
      return Showcase.sections.find { |section| section.id == :sheet }.examples.map { |example| example.calls[:data][/detents: ("[^"]*")/, 1] }.join(" · ")
    end
    return choices.keys.map { |key| ":#{key}" }.join(" · ") if choices
    return "Additional Tailwind classes" if parameter == :extra

    default = showcase_parameters(builder).to_h[parameter]
    %w[true false].include?(default) ? "true · false" : "—"
  end

  def showcase_partial_parameters(name)
    source = Lostcoords::Ui::Engine.root.join("app/views/lostcoords/ui/components/_#{name}.html.erb").read
    strict = source[/locals: \((.*?)\)/, 1]
    return parameter_rows("partial(#{strict})") if strict

    defaults = source.scan(/local_assigns\.fetch\(:([\w]+), ("[^"]*"|:[\w]+|\{\})/).to_h
    source.scan(/local_assigns\[:([\w]+)\]/).flatten.each { |key| defaults[key] ||= "nil" }
    defaults.to_a
  end

  def showcase_controller_options(section)
    controllers = { toast: %w[toast], sheet: %w[sheet], dialog: %w[sheet], menu: %w[row-menu], popover: %w[row-menu], emoji: %w[emoji-picker] }.fetch(section.id, [])
    controllers.flat_map do |identifier|
      files = [ "controllers/#{identifier.tr('-', '_')}_controller.js" ]
      files << "helpers/floating_panel.js" if %w[row-menu emoji-picker].include?(identifier)
      files << "helpers/catalog_picker.js" if identifier == "emoji-picker"
      files.flat_map do |file|
        source = Lostcoords::Ui::Engine.root.join("app/javascript/lostcoords/ui", file).read
        values = source[/static values = (\{[^\n]*\})/, 1] || source[/static values = (\{.*?^  \})/m, 1] || ""
        values.scan(/(\w+):\s*(?:\{\s*type:\s*(\w+),\s*default:\s*("[^"]*"|[\w.]+)\s*\}|(Boolean|String|Number))/).map do |name, type, default, shorthand|
          type ||= shorthand
          default ||= { "Boolean" => "false", "String" => '""', "Number" => "0" }.fetch(type)
          [ "data-#{identifier}-#{name.underscore.dasherize}-value", type, default ]
        end
      end
    end
  end

  def docs_link_class
    "flex min-h-11 items-center rounded-xl px-3 py-2 text-sm text-ink-2 transition-colors hover:bg-paper-2 hover:text-ink aria-[current=page]:bg-paper-2 aria-[current=page]:font-semibold aria-[current=page]:text-ink"
  end
end
