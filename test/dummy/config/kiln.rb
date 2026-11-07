Kiln.configure do |config|
  config.output = Rails.root.join("../../docs").to_s
  config.url = "https://ui.lostcoords.com"
  config.paths = :file
  config.cname = "ui.lostcoords.com"
  config.files = { "minisearch-license.txt" => "vendor/minisearch/LICENSE", "octicons-license.txt" => "vendor/octicons/LICENSE" }
  # Component demos and block previews link to placeholder anchors on purpose.
  config.verify_skip = [ "[data-example-preview]", "[data-controller~=block-preview]" ]
end

Kiln.pages do
  params :component, -> { Showcase.sections.map { { component: it.id } } }
  params :block, -> { DocsBlocks.all.map { { block: it.id } } }
  params :block_preview, -> { DocsBlocks.all.map { { block: it.id } } }
end
