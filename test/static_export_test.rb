require "test_helper"
require "lostcoords/ui/components"
require "lostcoords/ui/tokens"
require "open3"
require "json"
require "tmpdir"
require "uri"
require "digest"

class StaticExportTest < ActiveSupport::TestCase
  SOURCES = "{app,lib,config,test/dummy/app,test/dummy/config}/**/*"

  # The two passes run in separate processes, so an edit between them would look like a non-repeatable
  # export. A pass whose sources changed underneath it is retried instead.
  def export_twice
    3.times do
      before = source_digest
      directory = Dir.mktmpdir
      second = Dir.mktmpdir
      outputs = [ directory, second ].map do |target|
        Open3.capture3({ "RAILS_ENV" => "development" }, "bin/rails", "lostcoords:ui:showcase[#{target}]", chdir: Lostcoords::Ui::Engine.root)
      end
      return [ directory, second, outputs ] if source_digest == before

      FileUtils.rm_rf([ directory, second ])
    end
    flunk "Sources kept changing during the export"
  end

  def source_digest
    Dir.chdir(Lostcoords::Ui::Engine.root) do
      Digest::SHA256.hexdigest(Dir[SOURCES].select { |path| File.file?(path) && !path.include?("/builds/") }.sort.map { |path| "#{path}:#{File.mtime(path).to_f}" }.join("\n"))
    end
  end

  test "the exported pages resolve their assets and local navigation without Rails" do
    directory, second, outputs = export_twice
    begin
      outputs.each { |output, error, status| assert status.success?, "#{output}\n#{error}" }
      assert_equal "ui.lostcoords.com\n", File.read(File.join(directory, "CNAME"))
      reference = JSON.parse(File.read(File.join(directory, "api.json")))
      assert_equal Lostcoords::Ui::Components.all.size, reference.fetch("components").size
      assert_includes File.read(File.join(directory, "llms.txt")), "lc_button_to"
      installation = Nokogiri::HTML(File.read(File.join(directory, "installation.html")))
      assert_includes installation.text, "app/assets/tailwind/application.css"
      assert_includes File.read(File.join(directory, "starter.css")), '@import "../builds/tailwind/lostcoords_ui.css"'
      theming = Nokogiri::HTML(File.read(File.join(directory, "theming.html")))
      assert_equal "Theming", theming.at_css("h1").text
      pages = Dir["#{directory}/**/*.html"]
      assert_equal Showcase.sections.size + 7 + DocsBlocks.all.size * 2, pages.size
      assert_equal DocsBlocks.all.size, reference.fetch("blocks").size

      search = JSON.parse(File.read(File.join(directory, "search.json"))).fetch("documents")
      assert_operator search.size, :>, Showcase.sections.size
      assert search.any? { |document| document["text"].include?("lazyLoadControllersFrom") }, "Search indexes page text"
      targets = Hash.new { |cache, path| cache[path] = Nokogiri::HTML(File.read(File.join(directory, path))) }
      search.each do |document|
        path, fragment = document["url"].split("#", 2)
        assert File.file?(File.join(directory, path)), "Search links to a missing page: #{document["url"]}"
        next unless fragment

        assert targets[path].at_css("[id='#{fragment}']"), "Search links to a missing anchor: #{document["url"]}"
      end

      pages.each do |page|
        relative = Pathname(page).relative_path_from(directory).to_s
        assert_equal File.read(page), File.read(File.join(second, relative)), "Non-repeatable export: #{relative}"
      end

      pages.each do |page|
        document = Nokogiri::HTML(File.read(page))
        assert_empty document.css('input[name="authenticity_token"]'), "Static form leaked a CSRF token: #{page}"
        importmap = document.at_css('script[type="importmap"]')
        if importmap
          JSON.parse(importmap.content).fetch("imports").each_value do |path|
            assert_match(/-\h{8}\.js\z/, path)
            # Root-absolute, so every page's tracked importmap matches and Turbo visits never reload.
            assert_match %r{\A/assets/}, path, "#{page} has an invalid importmap URL: #{path}"
            assert File.file?(File.join(directory, path)), "Missing module: #{path} in #{page}"
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
    ensure
      FileUtils.rm_rf([ directory, second ])
    end
  end
end
