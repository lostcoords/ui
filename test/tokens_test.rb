require "test_helper"
require "lostcoords/ui/tokens"
require "tailwindcss/ruby"
require "open3"

module Lostcoords::Ui
  class TokensTest < ActiveSupport::TestCase
    test "the starter builds every component with defaults and no host token declarations" do
      Tailwindcss::Engines.bundle
      Dir.mktmpdir do |dir|
        _, error, status = Open3.capture3(
          Tailwindcss::Ruby.executable, "-i", "-", "-o", "#{dir}/theme.css",
          stdin_data: DocsInstallation.stylesheet, chdir: Rails.root.join("app/assets/tailwind")
        )
        assert status.success?, error
        css = File.read("#{dir}/theme.css")
        defined = css.scan(Tokens::DECLARATION).flatten
        required = css.scan(/var\(\s*(--[\w-]+)\s*\)/).flatten
        javascript = Dir[Engine.root.join("app/javascript/**/*.js")].map { |path| File.read(path) }.join("\n")
        required += javascript.scan(/getPropertyValue\(\s*["'](--[\w-]+)/).flatten
        set_by_javascript = javascript.scan(/setProperty\(\s*["'](--[\w-]+)/).flatten

        assert_empty (required.uniq - defined - set_by_javascript).reject { |name| name.start_with?("--tw-") }
        assert_includes css, "html[data-theme=\"dark\"]"
        assert_includes css, ".bg-sky"
        assert_includes css, ".ui-prose"
        assert_includes css, "prefers-reduced-motion"
      end
    end
  end
end
