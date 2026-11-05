module ShowcaseHelper
  # The header's brand mark, inlined so the static export needs no icon file. It follows the browser's color scheme.
  FAVICON = <<~SVG.squish.freeze
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 28 28" fill="none">
    <style>path{stroke:#111}@media (prefers-color-scheme:dark){path{stroke:#fff}}</style>
    <path d="M7 3v18h18M3 7h18v18M14 9v10M9 14h10" stroke-width="2"/></svg>
  SVG

  def showcase_favicon_tag
    tag.link(rel: "icon", type: "image/svg+xml", href: "data:image/svg+xml,#{ERB::Util.url_encode(FAVICON)}")
  end

  def showcase_components(section)
    components = Lostcoords::Ui::Components.all.index_by(&:name)
    section.components.map { |name| components.fetch(name) }
  end

  # Helpers the section's examples call that another page documents, with a link to that page's entry.
  def showcase_related(section)
    section.related.filter_map do |name|
      owner = Showcase.owner(name)
      [ name, "/components/#{owner.id}.html##{name}" ] if owner
    end
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

  def showcase_parameters(signature)
    node = Prism.parse("def #{signature}; end").value.statements.body.first.parameters
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

  def showcase_choices(name, signature, parameter)
    ui = Lostcoords::Ui
    choices = {
      lc_button: { variant: ui::ButtonHelper::BUTTON_VARIANTS.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_button_link_to: { variant: ui::ButtonHelper::BUTTON_VARIANTS.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_copy_button: { variant: ui::ButtonHelper::BUTTON_VARIANTS.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_button_to: { variant: ui::ButtonHelper::BUTTON_VARIANTS.keys, size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_icon_button: { shape: ui::ButtonHelper::ICON_BUTTON_SHAPES.keys, size: ui::ButtonHelper::ICON_BUTTON_SIZES.keys },
      lc_badge: { tone: ui::BadgeHelper::BADGE_TONES.keys, shape: ui::BadgeHelper::BADGE_SHAPES.keys },
      lc_avatar: { size: ui::BadgeHelper::AVATAR_SIZES.keys },
      lc_icon_badge: { size: ui::BadgeHelper::ICON_BADGE_SIZES.keys, shape: ui::BadgeHelper::ICON_BADGE_SHAPES.keys, tone: ui::BadgeHelper::BADGE_TONES.keys },
      lc_toggle: { size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_input: { size: ui::TailwindHelper::CONTROL_SIZES.keys, type: ui::StructuresHelper::INPUT_TYPES },
      lc_select: { size: ui::TailwindHelper::CONTROL_SIZES.keys },
      lc_card: { padding: ui::CardHelper::CARD_PADDING.keys },
      lc_dialog: { kind: ui::DialogHelper::DIALOGS.keys, size: ui::DialogHelper::DIALOG_SIZES.keys },
      lc_alert: { tone: ui::FeedbackHelper::ALERT_ICONS.keys },
      lc_toast: { tone: ui::FeedbackHelper::ALERT_ICONS.keys },
      lc_spinner: { size: ui::FeedbackHelper::SPINNER_SIZES.keys },
      lc_menu: { align: ui::MenuHelper::MENU_POPOVER_ALIGN.keys },
      lc_popover: { align: ui::MenuHelper::MENU_POPOVER_ALIGN.keys, trigger_variant: ui::ButtonHelper::BUTTON_VARIANTS.keys },
      lc_menu_option: { tone: ui::MenuHelper::MENU_OPTION_TONES.keys }
    }.dig(name, parameter)
    return choices.map { |key| ":#{key}" }.join(" · ") if choices
    return ":start · :end" if parameter == :icon_position
    return "Heroicon name; spacing is handled automatically" if parameter == :icon
    return "Native HTML attributes; class:, data: and aria: merge with defaults" if %i[attrs attributes].include?(parameter)
    return "Captured Rails ERB content" if showcase_parameters(signature).to_h[parameter] == "Captured block"
    return "fit · medium large · large" if parameter == :detents
    return "GET URL for lazy-loaded emoji catalog HTML" if parameter == :catalog_url
    return "Accessible name, visible where applicable" if parameter == :label
    return "true · false" if %w[true false].include?(showcase_parameters(signature).to_h[parameter])

    "—"
  end
end
