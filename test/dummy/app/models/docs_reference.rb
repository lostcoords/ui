module DocsReference
  def self.components
    usages = Showcase.sections.flat_map { |section| section.examples.map { [ section, it, it.builders ] } }
    Lostcoords::Ui::Components.all.map do |component|
      examples = usages.filter_map do |section, example, builders|
        next unless builders.include?(component.name)

        { title: example.title, url: "https://ui.lostcoords.com/components/#{section.id}.html", erb: example.source.gsub("EXAMPLE_ID", "my-component") }
      end
      owner = Showcase.owner(component.name)
      parts = DocsParts.for(component.name).map(&:signature)
      { name: component.name, signature: component.signature, url: ("https://ui.lostcoords.com/components/#{owner.id}.html##{component.name}" if owner), parts: parts.presence, examples: examples }.compact
    end
  end

  def self.json
    JSON.pretty_generate({ library: "lostcoords-ui", adapter: "Rails", components: components, blocks: blocks, tokens: Lostcoords::Ui::TOKENS, color_roles: Lostcoords::Ui::Tokens::COLORS, styles: Lostcoords::Ui::Builders.all.map(&:signature) }) + "\n"
  end

  def self.blocks
    DocsBlocks.all.map do |block|
      {
        id: block.id, title: block.title, description: block.description, docs_only: true,
        url: "https://ui.lostcoords.com#{block.url}", components: block.components, notes: block.notes,
        files: block.sources.map { |source| { path: source.label, language: source.language, source: source.content } }
      }
    end
  end

  def self.text
    lines = [ "# lostcoords-ui", "", "Rails rendering helpers with semantic HTML, native attributes and browser interactions.", "", "Install and styling: https://ui.lostcoords.com/installation.html", "Theming: https://ui.lostcoords.com/theming.html", "API JSON: https://ui.lostcoords.com/api.json", "", "Tailwind CSS v4 is required. Install the gem once; the Rails engine exposes all lc_* helpers without per-component imports.", "The engine includes a default light and dark theme. Override CSS variables only as needed. Use class: to merge Tailwind utilities, data: and aria: for native attributes. Block helpers capture Rails ERB.", "lc_button_to keeps Rails form, method and CSRF semantics. Each host application's lockfile pins its version.", "" ]
    lines += [ "## Theme colors", "", "Override only the roles you need. Soft status backgrounds are generated automatically. Primary controls actions, links, selection and focus.", "" ]
    Lostcoords::Ui::Tokens::COLORS.each { |name, description| lines << "- `#{name}`: #{description}" }
    lines << ""
    components.each do |component|
      lines += [ "## #{component[:name]}", "", *([ component[:url], "" ] if component[:url]), "```ruby", component[:signature], *component[:parts], "```", "" ]
      component[:examples].each do |example|
        lines += [ "#{example[:title]}: #{example[:url]}", "", "```erb", example[:erb], "```", "" ]
      end
    end
    lines += [ "## Blocks", "", "Docs-only composition examples: https://ui.lostcoords.com/blocks.html", "Copy and adapt the example files. Blocks are not importable library components.", "" ]
    blocks.each do |block|
      lines += [ "### #{block[:title]}", "", block[:description], block[:url], "" ]
      block[:notes].each { |note| lines += [ note, "" ] }
      block[:files].each do |file|
        lines += [ file[:path], "", "```#{file[:language]}", file[:source], "```", "" ]
      end
    end
    lines += [ "## Advanced styles", "", "Class helpers style custom markup; the application owns its behavior.", "Glass surfaces use lc_glass_class; lc_tw merges utility classes. Read https://github.com/lostcoords/ui#advanced-style-composition.", "" ]
    lines.concat(Lostcoords::Ui::Builders.all.map { |builder| "- `#{builder.signature}`" })
    lines.join("\n") + "\n"
  end
end
