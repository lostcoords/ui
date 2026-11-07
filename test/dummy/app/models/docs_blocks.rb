module DocsBlocks
  Source = Data.define(:path, :label, :language) do
    def content = Rails.root.join(path).read.strip
  end

  Block = Data.define(:id, :title, :description, :notes) do
    def partial = "blocks/examples/#{id}"
    def url = "/blocks/#{id}.html"
    def preview_url = "/blocks/#{id}/preview.html"

    def components
      builders = sources.first.content.scan(/\blc_\w+/).map(&:to_sym)
      Showcase.sections.filter_map { |section| section.id if (section.components & builders).any? }
    end

    # The ERB, plus the stylesheet and controller a block keeps beside the components, when it has them.
    def sources
      [
        Source.new("app/views/blocks/examples/_#{id}.html.erb", "app/views/shared/_#{id}.html.erb", :erb),
        (Source.new(stylesheet_path, "app/assets/stylesheets/#{id}.css", :css) if stylesheet?),
        (Source.new(controller_path, "app/javascript/controllers/blocks_#{id}_controller.js", :javascript) if controller?)
      ].compact
    end

    def stylesheet? = Rails.root.join(stylesheet_path).file?
    def controller? = Rails.root.join(controller_path).file?

    private
      def stylesheet_path = "app/assets/stylesheets/blocks/#{id}.css"
      def controller_path = "app/javascript/controllers/blocks_#{id}_controller.js"
  end

  def self.all
    [
      Block.new(:application_header, "Application header", "A glass header with navigation, an account menu and room for your brand.", [
        "Replace the sample brand, links and account actions with your application's content.",
        "lc_app_header handles the glass and the scroll behavior. Keep destinations in header.nav and account actions in a menu inside header.actions."
      ]),
      Block.new(:docs_shell, "Documentation layout", "A sidebar, page content and an \"On this page\" list, with a collapsible menu on phones.", [
        "lc_docs_shell takes the sidebar as navigation: and an lc_toc as contents:, with the page as its block. This documentation site uses it for every guide and component page.",
        "Mark the current page with current: true so the sidebar sets aria-current. The contents list appears from the xl breakpoint and marks the section you have scrolled to."
      ]),
      Block.new(:mobile_navigation, "Mobile navigation", "A floating navigation pill and an expanding stack of quick actions.", [
        "Choose a small set of primary destinations and replace the sample quick actions.",
        "lc_dock keeps the safe-area spacing, reserves room at the end of the page and hides while the keyboard is open. The panel switching in this preview is the example's own controller."
      ])
    ]
  end

  def self.find(id) = all.find { |block| block.id.to_s == id.to_s }
end
