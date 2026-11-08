Kiln.configure do |config|
  config.output = Rails.root.join("../../docs")
  config.url = "https://ui.lostcoords.com"
  config.paths = :file
  config.cname = true
  config.files = { "minisearch-license.txt" => "vendor/minisearch/LICENSE", "octicons-license.txt" => "vendor/octicons/LICENSE" }
  # Component demos and block previews link to placeholder anchors on purpose.
  config.verify_skip = [ "[data-example-preview]", "[data-controller~=block-preview]" ]
end

blocks = -> { DocsBlocks.all.map { { block: it.id } } }

Kiln.pages do
  params :component, -> { Showcase.sections.map { { component: it.id } } }
  params :block, blocks
  params :block_preview, blocks
end
