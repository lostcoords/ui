require "lostcoords/ui/components"
require "lostcoords/ui/tokens"

# The documents behind the docs search dialog, served as /search.json. MiniSearch indexes
# them in the browser, so search works the same on the dev server and the static export.
#
# Named entries (components, helpers, examples, blocks, color roles) come from the models.
# Their text and every other section's come from the rendered pages, through Kiln.render: each
# element with an id that holds a heading is one section, and its visible text is what search
# matches. During a build each page renders once, shared with the build.
module DocsSearch
  singleton_class.include Rails.application.routes.url_helpers

  GROUPS = {
    "Guides" => "book-open",
    "Components" => "squares-2x2",
    "Helpers" => "code-bracket",
    "Examples" => "eye",
    "Blocks" => "rectangle-group",
    "Color roles" => "swatch"
  }.freeze

  Document = Data.define(:group, :title, :detail, :url, :keywords, :text, :featured) do
    def initialize(group:, title:, detail:, url:, keywords: "", text: "", featured: false) = super
  end

  HEADINGS = "h1, h2, h3, h4".freeze
  # Code, demos and navigation repeat across pages, so they would drown the prose out.
  SKIPPED = "pre, svg, script, template, nav, button, details, [aria-hidden=true], [data-example-preview]".freeze
  HEADING_TAGS = %w[h1 h2 h3 h4].freeze
  # Every component page repeats these intros word for word, so they would match everywhere.
  PAGE_PARTS = %w[usage examples api].freeze

  def self.json
    JSON.generate(icons: GROUPS, documents: documents.map(&:to_h)) + "\n"
  end

  def self.documents
    all = Showcase.sections
    chunks = pages(all).to_h { |url| [ url, sections(Kiln.render(url), url).except(*PAGE_PARTS.map { |id| "#{url}##{id}" }) ] }
    named = named_documents(all).map do |document|
      next document if document.group == "Color roles"

      chunk = chunks[document.url.split("#").first]&.delete(document.url) || {}
      document.with(text: [ document.text, chunk[:text] ].compact_blank.join(" "))
    end

    guides = [ installation_path, theming_path, component_path(:foundations) ].flat_map do |url|
      page_title = chunks[url][url][:title]
      chunks.delete(url).map do |anchor, chunk|
        top = anchor == url
        Document.new(group: "Guides", title: chunk[:title], detail: top ? chunk[:text].split(/(?<=\.)\s/).first : page_title, url: anchor, text: chunk[:text], featured: top)
      end
    end

    # Whatever is left on component and block pages (usage notes, extra sections) belongs to the page's own entry.
    named = named.map do |document|
      rest = chunks.delete(document.url)&.values&.map { |chunk| "#{chunk[:title]} #{chunk[:text]}" }
      rest ? document.with(text: [ document.text, *rest ].compact_blank.join(" ")) : document
    end

    extras = [
      Document.new(group: "Guides", title: "All components", detail: "Every component, A to Z.", url: components_path, featured: true),
      Document.new(group: "Guides", title: "Blocks", detail: "Composition examples to copy into your app.", url: blocks_path, featured: true),
      Document.new(group: "Guides", title: "api.json", detail: "The machine-readable reference for agents and tooling.", url: "/api.json", keywords: "json api agents llm"),
      Document.new(group: "Guides", title: "llms.txt", detail: "The plain-text reference for language models.", url: "/llms.txt", keywords: "agents llm ai")
    ]
    guides + extras + named
  end

  def self.named_documents(all)
    components = Lostcoords::Ui::Components.all
    owners = all.flat_map { |section| section.components.map { |name| [ name, section ] } }.to_h
    # Example#builders rebuilds the component list on every call; one list serves every example here.
    names = components.map(&:name)
    helpers = ->(example) { example.source.scan(/\blc_\w+/).uniq.map(&:to_sym) & names }

    [
      *all.reject { |section| section.id == :foundations }.sort_by(&:title).map do |section|
        Document.new(group: "Components", title: section.title, detail: section.description, url: component_path(section.id), keywords: section.components.join(" "))
      end,
      *components.filter_map do |component|
        next unless (owner = owners[component.name])

        parts = DocsParts.for(component.name)
        Document.new(group: "Helpers", title: component.name.to_s, detail: owner.title, url: component_path(owner.id, anchor: component.name),
          keywords: parts.map(&:name).join(" "), text: [ component.signature, *parts.map(&:signature) ].join(" "))
      end,
      *all.flat_map do |section|
        section.examples.each_with_index.map do |example, index|
          Document.new(group: "Examples", title: example.title, detail: section.title, url: component_path(section.id, anchor: "example-#{index}"), keywords: [ section.title, *helpers.(example) ].join(" "))
        end
      end,
      *DocsBlocks.all.map do |block|
        Document.new(group: "Blocks", title: block.title, detail: block.description, url: block.url, keywords: block.components.join(" "), text: block.notes.join(" "))
      end,
      *Lostcoords::Ui::Tokens::COLORS.map do |name, description|
        Document.new(group: "Color roles", title: name.to_s, detail: description, url: theming_path(anchor: "color-roles"), keywords: "color token")
      end
    ]
  end

  # Every page with prose: the guides, each component and each block.
  def self.pages(all)
    [ installation_path, theming_path, *all.map { component_path(it.id) }, *DocsBlocks.all.map(&:url) ]
  end

  # { url => { title:, text: } } for the page itself and each section on it. Each piece of text
  # belongs to the closest section around it; text outside every section belongs to the page.
  def self.sections(html, url)
    document = Nokogiri::HTML5(html)
    root = document.at_css("main") || document.body
    root.css(SKIPPED).each(&:remove)
    chunks = Hash.new { |hash, key| hash[key] = { title: nil, text: +"" } }
    chunks[url][:title] = root.at_css("h1")&.text&.squish
    walk = lambda do |node, key|
      if node.text?
        chunks[key][:text] << " " << node.text
        return
      end
      return if !node.element? || HEADING_TAGS.include?(node.name)

      if (anchor = anchor(node)) && node != root
        key = "#{url}##{anchor[:id]}"
        chunks[key][:title] ||= anchor[:heading].text.squish
      end
      node.children.each { |child| walk.(child, key) }
    end
    root.children.each { |child| walk.(child, url) }
    chunks.transform_values { |chunk| { title: chunk[:title], text: chunk[:text].squish } }.reject { |_, chunk| chunk[:title].blank? }
  end

  # A section is an element with an id that holds a heading, or a block whose first child is a
  # heading with the id, as each entry in the API reference is.
  def self.anchor(node)
    if node["id"] && (heading = node.at_css(HEADINGS))
      { id: node["id"], heading: }
    elsif (first = node.element_children.first) && HEADING_TAGS.include?(first.name) && first["id"]
      { id: first["id"], heading: first }
    end
  end
  private_class_method :named_documents, :pages, :sections, :anchor
end
