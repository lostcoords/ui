require "test_helper"
require "lostcoords/ui/components"
require "lostcoords/ui/tokens"
require "open3"
require "json"
require "tmpdir"
require "uri"

class StaticExportTest < ActiveSupport::TestCase
  test "the exported pages resolve their assets and local navigation without Rails" do
    Dir.mktmpdir do |directory|
      root = Lostcoords::Ui::Engine.root
      output, error, status = Open3.capture3({ "RAILS_ENV" => "development" }, "bin/rails", "lostcoords:ui:showcase[#{directory}]", chdir: root)
      assert status.success?, "#{output}\n#{error}"
      assert_equal "ui.lostcoords.com\n", File.read(File.join(directory, "CNAME"))
      reference = JSON.parse(File.read(File.join(directory, "api.json")))
      assert_equal Lostcoords::Ui::Components.all.size, reference.fetch("components").size
      assert_includes File.read(File.join(directory, "llms.txt")), "ui_button_to"
      installation = Nokogiri::HTML(File.read(File.join(directory, "installation.html")))
      assert_includes installation.text, "app/assets/tailwind/application.css"
      assert_includes File.read(File.join(directory, "starter.css")), '@import "../builds/tailwind/lostcoords_ui.css"'
      theming = Nokogiri::HTML(File.read(File.join(directory, "theming.html")))
      assert_equal "Theming", theming.at_css("h1").text
      pages = Dir["#{directory}/**/*.html"]
      assert_equal Showcase.sections.size + 6 + DocsBlocks.all.size * 2, pages.size
      assert_equal DocsBlocks.all.size, reference.fetch("blocks").size

      Dir.mktmpdir do |second|
        _, error, status = Open3.capture3({ "RAILS_ENV" => "development" }, "bin/rails", "lostcoords:ui:showcase[#{second}]", chdir: root)
        assert status.success?, error
        pages.each do |page|
          relative = Pathname(page).relative_path_from(directory).to_s
          assert_equal File.read(page), File.read(File.join(second, relative)), "Non-repeatable export: #{relative}"
        end
      end

      pages.each do |page|
        document = Nokogiri::HTML(File.read(page))
        assert_empty document.css('input[name="authenticity_token"]'), "Static form leaked a CSRF token: #{page}"
        importmap = document.at_css('script[type="importmap"]')
        if importmap
          JSON.parse(importmap.content).fetch("imports").each_value do |path|
            assert_match(/-\h{8}\.js\z/, path)
            assert_match %r{\A\.\.?/}, path, "#{page} has an invalid importmap URL: #{path}"
            assert File.file?(File.expand_path(path, File.dirname(page))), "Missing module: #{path} in #{page}"
          end
        end
        document.css("a[href], link[href], script[src], iframe[src]").each do |node|
          path = URI.parse(node["href"] || node["src"])
          next if path.scheme || path.host || path.path.empty?

          target = path.path.start_with?("/") ? File.join(directory, path.path) : File.expand_path(path.path, File.dirname(page))
          target = File.join(target, "index.html") if File.directory?(target)
          assert File.file?(target), "Broken export link: #{path} in #{page}"
        end
      end
    end
  end
end
