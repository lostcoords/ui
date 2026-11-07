require "test_helper"
require "kiln/test_helper"
require "lostcoords/ui/components"

# Kiln fails the build on broken links, missing anchors, missing importmap modules and render errors,
# and strips CSRF tokens. This test keeps the checks specific to the docs.
class StaticExportTest < ActiveSupport::TestCase
  include Kiln::TestHelper

  test "the docs export is complete and repeatable" do
    kiln_build(repeatable: true) do |directory|
      assert_equal "ui.lostcoords.com\n", directory.join("CNAME").read
      reference = JSON.parse(directory.join("api.json").read)
      assert_equal Lostcoords::Ui::Components.all.size, reference.fetch("components").size
      assert_equal DocsBlocks.all.size, reference.fetch("blocks").size
      assert_includes directory.join("llms.txt").read, "lc_button_to"
      assert_includes Nokogiri::HTML(directory.join("installation.html").read).text, "app/assets/tailwind/application.css"
      assert_includes directory.join("starter.css").read, '@import "../builds/tailwind/lostcoords_ui.css"'
      assert_equal "Theming", Nokogiri::HTML(directory.join("theming.html").read).at_css("h1").text
      assert_equal Showcase.sections.size + 7 + DocsBlocks.all.size * 2, Dir[directory.join("**/*.html")].size

      search = JSON.parse(directory.join("search.json").read).fetch("documents")
      assert_operator search.size, :>, Showcase.sections.size
      assert search.any? { |document| document["text"].include?("lazyLoadControllersFrom") }, "Search indexes page text"
      search.each do |document|
        path, fragment = document["url"].split("#", 2)
        page = directory.join(path.delete_prefix("/"))
        assert page.file?, "Search links to a missing page: #{document["url"]}"
        assert Nokogiri::HTML(page.read).at_css("[id='#{fragment}']"), "Search links to a missing anchor: #{document["url"]}" if fragment
      end

      # Root-absolute, digested module URLs keep every page's tracked importmap identical, so Turbo visits never reload.
      Dir[directory.join("**/*.html")].each do |page|
        importmap = Nokogiri::HTML(File.read(page)).at_css('script[type="importmap"]') or next
        JSON.parse(importmap.content).fetch("imports").each_value do |url|
          assert_match %r{\A/assets/.+-\h{8}\.js\z}, url, "#{page} has an invalid importmap URL"
        end
      end
    end
  end
end
