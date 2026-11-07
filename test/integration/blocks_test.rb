require "test_helper"

class BlocksTest < ActionDispatch::IntegrationTest
  test "blocks are documented as copyable examples with their real source files" do
    get "/blocks.html"
    assert_response :success

    DocsBlocks.all.each do |block|
      get block.url
      assert_response :success
      document = Nokogiri::HTML(response.body)
      assert_equal block.preview_url, document.at_css("iframe")["src"]
      assert_equal block.sources.map(&:content), document.css("pre code").map(&:text)

      get block.preview_url
      assert_response :success
      assert_includes response.body, "data-controller=\"block-preview\""
      assert_includes response.body, "<title>#{block.title} · Block preview</title>"
      refute_includes response.body, "data-controller=\"showcase\""
    end
  end

  test "unknown block pages and previews are not found" do
    get "/blocks/missing.html"
    assert_response :not_found
    get "/blocks/missing/preview.html"
    assert_response :not_found
  end

  test "machine references distinguish docs examples from component APIs" do
    get "/api.json"
    assert_response :success
    reference = JSON.parse(response.body)
    assert_equal DocsBlocks.all.map { |block| block.id.to_s }, reference.fetch("blocks").map { |block| block.fetch("id") }
    reference.fetch("blocks").each do |block|
      assert block.fetch("docs_only")
      assert_equal DocsBlocks.find(block.fetch("id")).sources.map { it.language.to_s }, block.fetch("files").map { |file| file.fetch("language") }
      assert_equal "erb", block.fetch("files").first.fetch("language")
    end
    assert_equal Lostcoords::Ui::Components.all.size, reference.fetch("components").size

    get "/llms.txt"
    assert_response :success
    assert_includes response.body, "Blocks are not importable library components"
    DocsBlocks.all.each { |block| assert_includes response.body, block.url }
  end
end
