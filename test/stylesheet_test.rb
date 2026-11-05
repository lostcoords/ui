require "test_helper"
require "open3"
require "tailwindcss/ruby"

module Lostcoords::Ui
  class StylesheetTest < ActiveSupport::TestCase
    test "the component entry compiles without document styles" do
      Dir.mktmpdir do |dir|
        input = File.join(dir, "input.css")
        File.write(input, <<~CSS)
          @import "tailwindcss/theme.css";
          @import "tailwindcss/utilities.css";
          @plugin "@tailwindcss/typography";
          @import "#{Lostcoords::Ui.root.join('app/assets/tailwind/lostcoords/ui/components.css')}";
        CSS
        _, error, status = Open3.capture3(Tailwindcss::Ruby.executable, "-i", input, "-o", "#{dir}/out.css")
        assert status.success?, error
        css = File.read("#{dir}/out.css")
        assert_includes css, ".lc-copy-content"
        assert_includes css, ".lc-prose"
        refute css.match?(/\n\s*body\s*\{/), "Component CSS contains a document body rule"
        refute css.match?(/(?:^|[{}])\s*:where\(code\):not\(:where\(pre code\)\)/m), "Component CSS styles host inline code"
        refute_includes css, "--text-sm--line-height: initial"
      end
    end

    test "a granular build carries only the entries it imports" do
      Dir.mktmpdir do |dir|
        Stylesheets.write(dir)
        input = File.join(dir, "input.css")
        File.write(input, <<~CSS)
          @import "tailwindcss/theme.css";
          @import "tailwindcss/utilities.css" source(none);
          @import "./lostcoords_ui/core.css";
          @import "./lostcoords_ui/components/dialog.css";
        CSS
        _, error, status = Open3.capture3(Tailwindcss::Ruby.executable, "-i", input, "-o", "#{dir}/out.css")
        assert status.success?, error
        css = File.read("#{dir}/out.css")
        assert_includes css, ".lc-card"
        assert_includes css, ".lc-dialog"
        assert_includes css, ".h-control-md"
        # min-w-64 only appears in the menu helper, so it proves other entries' sources stay unscanned.
        %w[.lc-emoji-picker .lc-code-block .lc-tooltip .lc-toast-region .lc-table .min-w-64].each do |selector|
          refute_includes css, selector, "#{selector} ships without its entry"
        end
        assert_equal Stylesheets.entries.size, Dir["#{dir}/lostcoords_ui/**/*.css"].size
      end
    end

    test "a host build reaches the gem's stylesheet and scans its helpers through the engines entry" do
      Tailwindcss::Engines.bundle
      generated = Rails.root.join("app/assets/builds/tailwind/lostcoords_ui.css").read
      target = generated[/@import "([^"]+)"/, 1]

      assert Pathname(target).absolute?, generated
      assert File.file?(target), generated

      Dir.mktmpdir do |dir|
        _, error, status = Open3.capture3(Tailwindcss::Ruby.executable, "-i", Rails.root.join("app/assets/tailwind/application.css").to_s, "-o", "#{dir}/out.css")
        assert status.success?, error
        css = File.read("#{dir}/out.css")
        assert_includes css, ".duration-\\(--lc-motion-control\\)"
        assert_includes css, ".lc-copy-content"
        assert css.include?(".not-first\\:pt-section"), "Missing spacing between navigation groups"
        assert css.include?(".pb-tight"), "Missing spacing beneath navigation group titles"
      end
    end
  end
end
