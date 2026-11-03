require "test_helper"
require "open3"

class StandaloneTest < ActiveSupport::TestCase
  test "components and icons render without loading Rails or the Heroicons gem" do
    script = <<~'RUBY'
      require "lostcoords/ui/action_view"
      require "lostcoords/ui"
      view = ActionView::Base.with_empty_template_cache.with_view_paths(Lostcoords::Ui.view_paths)
      view.extend(Lostcoords::Ui::Helpers)
      button = Nokogiri::HTML.fragment(view.lc_button("Save <draft>", icon: "check")).at_css("button")
      abort "button content" unless button.text == "Save <draft>" && button.at_css("svg") && !button.at_css("draft")
      input = Nokogiri::HTML.fragment(view.lc_input(name: "title", value: "<draft>")).at_css("input")
      abort "input value" unless input["value"] == "<draft>"
      abort "card content" unless view.lc_card { "Content" }.include?("Content")
      abort "partial lookup" unless view.lc_disclosure(title: "Details") { "Body" }.include?("<details")
      I18n.with_locale(:ja) do
        abort "translation" unless view.lc_copy_button(value: "text").include?("コピー")
      end
      view.define_singleton_method(:t) { |*| raise "host translation helper called" }
      view.define_singleton_method(:lc_locale) { :ja }
      abort "view locale" unless view.lc_copy_button(value: "text").include?("コピー")
      paths = I18n.load_path.dup
      Lostcoords::Ui.load_translations!
      abort "duplicate locales" unless I18n.load_path == paths
      abort "emoji data" unless view.lc_emoji_picker_count.positive?
      abort "Rails loaded" if defined?(Rails::Engine) || defined?(Rails::Application)
      abort "Heroicons loaded" if defined?(Heroicons)
      forbidden = %w[rails railties actionpack importmap-rails heroicons]
      abort "Rails dependency" unless (Bundler.load.specs.map(&:name) & forbidden).empty?
      legacy = JSON.parse(File.read(Lostcoords::Ui.root.join("config/helper_renames.json"))).keys
      abort "legacy helper" if legacy.any? { |name| view.respond_to?(name, true) }
      abort "helper namespace" unless Lostcoords::Ui::Helpers.instance_methods.all? { |name| name.to_s.start_with?("lc_") }
      puts "standalone rendering passed"
    RUBY
    environment = { "BUNDLE_GEMFILE" => Lostcoords::Ui.root.join("test/standalone/Gemfile").to_s }
    output, error, status = Open3.capture3(environment, "bundle", "exec", "ruby", "-Ilib", "-e", script, chdir: Lostcoords::Ui.root)
    assert status.success?, "#{output}\n#{error}"
    assert_includes output, "standalone rendering passed"
  end
end
