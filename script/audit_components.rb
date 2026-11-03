require "json"
require_relative "../lib/lostcoords/ui/action_view"
require_relative "../lib/lostcoords/ui/components"
require_relative "../test/dummy/app/models/showcase"

view = ActionView::Base.with_empty_template_cache.with_view_paths(Lostcoords::Ui.view_paths)
view.extend(Lostcoords::Ui::Helpers)
components = Lostcoords::Ui::Components.all
retired = %i[lc_status_pill lc_medallion lc_eyebrow lc_card_surface lc_form_card lc_sheet lc_pill_row lc_form_actions lc_pill lc_segmented lc_segmented_tab lc_form_alert lc_disclosure]
retired += retired.map { |name| "#{name}_class".to_sym } + [ :lc_icon_medallion_class ]
button = Nokogiri::HTML.fragment(view.lc_button("Save")).at_css("button")
checks = {
  retired_helpers_removed: retired.none? { |name| view.respond_to?(name) },
  avatar_large_is_distinct: view.lc_avatar_class(size: :lg) != view.lc_avatar_class,
  button_defaults_match: view.lc_button_class == button["class"],
  feedback_tones_match: Lostcoords::Ui::BadgeHelper::BADGE_TONES.keys.sort == Lostcoords::Ui::FeedbackHelper::ALERT_ICONS.keys.sort,
  all_components_documented: (components.map(&:name) - Showcase.builders).empty?
}
puts JSON.pretty_generate(
  catalog_pages: Showcase.sections.size,
  rendering_helpers: components.size,
  style_and_support_helpers: Lostcoords::Ui::Builders.all.size,
  checks: checks,
  pages: Showcase.sections.map { |section| { name: section.title, helpers: section.builders } },
  helpers: components.map { |component| { name: component.name, file: Pathname(component.path).relative_path_from(Lostcoords::Ui.root).to_s, line: component.line } }
)
abort "Component audit failed" unless checks.values.all?
