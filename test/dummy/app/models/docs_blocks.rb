module DocsBlocks
  Source = Data.define(:path, :label, :language) do
    def content = Rails.root.join(path).read.strip
  end

  Block = Data.define(:id, :title, :description, :notes) do
    def partial = "blocks/demos/#{id}"
    def url = "/blocks/#{id}.html"
    def preview_url = "/blocks/#{id}/preview.html"

    def components
      builders = sources.first.content.scan(/\blc_\w+/).map(&:to_sym)
      Showcase.sections.filter_map { |section| section.id if (section.components & builders).any? }
    end

    def sources
      controller = { application_header: "blocks_header", mobile_navigation: "blocks_mobile_navigation", global_search: "blocks_search" }[id]
      [
        Source.new("app/views/blocks/examples/_#{id}.html.erb", "app/views/shared/_#{id}.html.erb", :erb),
        Source.new("app/assets/stylesheets/blocks/#{id}.css", "app/assets/stylesheets/#{id}.css", :css),
        (Source.new("app/javascript/controllers/#{controller}_controller.js", "app/javascript/controllers/#{controller}_controller.js", :javascript) if controller)
      ].compact
    end
  end

  def self.all
    [
      Block.new(:application_header, "Application header", "A glass header with navigation, an account menu and room for your brand.", [
        "Replace the sample brand, links and account actions with your application's content.",
        "Keep navigation destinations as links and account actions in the menu. The header's layout and scroll behavior live in the example files."
      ]),
      Block.new(:docs_shell, "Documentation layout", "A sidebar, page content and an \"On this page\" list, with a collapsible menu on phones.", [
        "Render it as a layout: pass the sidebar and contents lists as locals and the page as the block. This documentation site uses it for every guide and component page.",
        "Mark the current page with current: true so the sidebar sets aria-current. The contents list appears from the xl breakpoint."
      ]),
      Block.new(:mobile_navigation, "Mobile navigation", "A floating navigation pill and an expanding stack of quick actions.", [
        "Choose a small set of primary destinations and replace the sample quick actions.",
        "Copy the bottom spacing and safe-area rules with the controls, so page content remains reachable. Test keyboard visibility on a real phone."
      ]),
      Block.new(:global_search, "Global search", "A search trigger that expands into a focused overlay with grouped results.", [
        "This example filters sample results in the browser so it also works on the static documentation site.",
        "Replace the sample results with your own data or a Turbo Frame endpoint. Keep permissions, ranking and fetching in your application."
      ])
    ]
  end

  def self.find(id) = all.find { |block| block.id.to_s == id.to_s }
end
