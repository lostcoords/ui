module ShowcaseHelper
  def showcase_builders(section)
    components = Lostcoords::Ui::Components.all.index_by(&:name)
    section.builders.filter_map { |name| components[name] }
  end

  def showcase_title(example, _index) = example.title

  def showcase_source(example, id:)
    example.source.gsub("EXAMPLE_ID", id)
  end

  def highlight_source(source, language: :erb)
    safe_join(SourceCode.tokens(source, language: language).map do |type, text|
      type ? tag.span(text, class: SourceCode::STYLES.fetch(type), data: { syntax: type }) : text
    end)
  end

  def showcase_parameters(component)
    node = Prism.parse("def #{component.signature}; end").value.statements.body.first.parameters
    return [] unless node

    (node.requireds + node.optionals + node.posts + node.keywords + [ node.rest, node.keyword_rest, node.block ].compact).map do |parameter|
      default = case parameter
      when Prism::KeywordRestParameterNode then "{}"
      when Prism::BlockParameterNode then "Captured block"
      else parameter.respond_to?(:value) ? parameter.value.slice : "Required"
      end
      [ parameter.name, default ]
    end
  end

  def showcase_choices(component, parameter)
    ui = Lostcoords::Ui
    choices = {
      lc_button: { variant: ui::PrimitivesHelper::BUTTON_STYLES.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_button_link_to: { variant: ui::PrimitivesHelper::BUTTON_STYLES.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_copy_button: { variant: ui::PrimitivesHelper::BUTTON_STYLES.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_button_to: { variant: ui::PrimitivesHelper::BUTTON_STYLES.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_icon_button: { shape: ui::ButtonHelper::ICON_BUTTON_SHAPES.keys, size: ui::ButtonHelper::ICON_BUTTON_SIZES.keys },
      lc_badge: { tone: ui::BadgeHelper::BADGE_TONES.keys },
      lc_status_pill: { tone: ui::BadgeHelper::STATUS_PILL_TONES.keys },
      lc_avatar: { size: ui::BadgeHelper::AVATAR_SIZES.keys },
      lc_icon_badge: { size: ui::BadgeHelper::ICON_BADGE_SIZES.keys },
      lc_medallion: { size: ui::BadgeHelper::ICON_MEDALLION_SIZES.keys, tone: ui::BadgeHelper::ICON_MEDALLION_TONES.keys },
      lc_pill: { size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_input: { size: ui::TailwindHelper::CONTROL_SIZES.keys, type: ui::StructuresHelper::INPUT_TYPES },
      lc_select: { size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_form_card: { padding: ui::CardHelper::FORM_CARD_PADDINGS.keys },
      lc_dialog: { kind: ui::DialogHelper::DIALOGS.keys },
      lc_form_alert: { tone: ui::FormHelper::FORM_ALERT_ICONS.keys },
      lc_spinner: { size: ui::FeedbackHelper::SPINNER_SIZES.keys },
      lc_menu: { align: ui::MenuHelper::MENU_POPOVER_ALIGN.keys },
      lc_popover: { align: ui::MenuHelper::MENU_POPOVER_ALIGN.keys },
      lc_menu_option: { tone: ui::MenuHelper::MENU_OPTION_TONES.keys }
    }.dig(component.name, parameter)
    return choices.map { |key| ":#{key}" }.join(" · ") if choices
    return ":start · :end" if parameter == :icon_position
    return "Heroicon name; spacing is handled automatically" if parameter == :icon
    return "Native HTML attributes; class:, data: and aria: merge with defaults" if %i[attrs attributes].include?(parameter)
    return "Captured Rails ERB content" if parameter == :block
    return "fit · medium large · large" if parameter == :detents
    return "GET URL for lazy-loaded emoji catalog HTML" if parameter == :catalog_url
    return "Accessible name, visible where applicable" if parameter == :label
    return "true · false" if %w[true false].include?(showcase_parameters(component).to_h[parameter])

    "—"
  end

  def docs_link_class
    "flex min-h-11 items-center rounded-xl px-3 py-2 text-sm text-ink-2 transition-colors hover:bg-paper-2 hover:text-ink aria-[current=page]:bg-paper-2 aria-[current=page]:font-semibold aria-[current=page]:text-ink"
  end
end
