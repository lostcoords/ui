require "test_helper"
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
      pages = Dir["#{directory}/**/*.html"]
      assert_equal Showcase.sections.size + 3, pages.size

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
        document.css("a[href], link[href], script[src]").each do |node|
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
