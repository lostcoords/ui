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
      table = Nokogiri::HTML.fragment(view.lc_table(id: "records", data: { records: true }) { view.tag.caption("Records <draft>") }).at_css("table")
      abort "native table" unless table["id"] == "records" && table.key?("data-records") && table.at_css("caption").text == "Records <draft>" && !table.at_css("draft")
      abort "partial lookup" unless view.lc_collapsible(title: "Details") { "Body" }.include?("<details")
      code = Nokogiri::HTML.fragment(view.lc_code_block("<script>example</script>\nnext line", id: "snippet", max_lines: 1))
      abort "code source" unless code.at_css("pre code").text == "<script>example</script>\nnext line" && !code.at_css("script")
      abort "code behavior" unless code.at_css('[data-controller="lc-code-block"]') && code.at_css('[data-lc-copy-source-value="snippet-content"]') && code.at_css('[data-lc-code-block-target="toggle"]')
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
      abort "helper namespace" unless Lostcoords::Ui::Helpers.instance_methods.all? { |name| name.to_s.start_with?("lc_") }
      puts "standalone rendering passed"
    RUBY
    environment = {
      "BUNDLE_GEMFILE" => Lostcoords::Ui.root.join("test/standalone/Gemfile").to_s,
      "BUNDLE_LOCKFILE" => Lostcoords::Ui.root.join("test/standalone/Gemfile.lock").to_s,
      "BUNDLE_FROZEN" => "true",
      "BUNDLE_PATH" => Bundler.settings[:path] && File.expand_path(Bundler.settings[:path], Lostcoords::Ui.root)
    }
    output, error, status = Bundler.with_unbundled_env do
      Open3.capture3(environment, "bundle", "exec", "ruby", "-Ilib", "-e", script, chdir: Lostcoords::Ui.root)
    end
    assert status.success?, "#{output}\n#{error}"
    assert_includes output, "standalone rendering passed"
  end
end
