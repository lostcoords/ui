module DocsReference
  def self.components
    Lostcoords::Ui::Components.all.map do |component|
      examples = Showcase.sections.flat_map do |section|
        section.examples.filter_map do |example|
          next unless example.builders.include?(component.name)

          { title: example.title, url: "https://ui.lostcoords.com/components/#{section.id}.html", erb: example.source.gsub("EXAMPLE_ID", "my-component") }
        end
      end
      { name: component.name, signature: component.signature, examples: examples }
    end
  end

  def self.json
    JSON.pretty_generate({ library: "lostcoords-ui", adapter: "Rails", components: components, blocks: blocks, tokens: Lostcoords::Ui::TOKENS, styles: Lostcoords::Ui::Builders.all.map(&:signature) }) + "\n"
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
    lines = [ "# lostcoords-ui", "", "Rails rendering helpers with semantic HTML, native attributes and browser interactions.", "", "Install and styling: https://ui.lostcoords.com/installation.html", "Theming: https://ui.lostcoords.com/theming.html", "API JSON: https://ui.lostcoords.com/api.json", "", "Tailwind CSS v4 is required. Install the gem once; the Rails engine exposes all ui_* helpers without per-component imports.", "The engine includes a default light and dark theme. Override CSS variables only as needed. Use class: to merge Tailwind utilities, data: and aria: for native attributes. Block helpers capture Rails ERB.", "ui_button_to keeps Rails form, method and CSRF semantics. Each host application's lockfile pins its version.", "" ]
    components.each do |component|
      lines += [ "## #{component[:name]}", "", "```ruby", component[:signature], "```", "" ]
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
    lines += [ "## Advanced styles", "", "Class helpers style custom markup; the application owns its behavior.", "Glass surfaces use glass_class; tw merges utility classes. Read https://github.com/lostcoords/ui#advanced-style-composition.", "" ]
    lines.concat(Lostcoords::Ui::Builders.all.map { |builder| "- `#{builder.signature}`" })
    lines.join("\n") + "\n"
  end
end
