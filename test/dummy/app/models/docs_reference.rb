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
    JSON.pretty_generate({ library: "lostcoords-ui", adapter: "Rails", components: components, tokens: Lostcoords::Ui::TOKENS, styles: Lostcoords::Ui::Builders.all.map(&:signature) }) + "\n"
  end

  def self.text
    lines = [ "# lostcoords-ui", "", "Rails rendering helpers with semantic HTML, native attributes and browser interactions.", "", "Install and styling: https://github.com/lostcoords/ui", "Theme tokens: https://ui.lostcoords.com/tokens.html", "API JSON: https://ui.lostcoords.com/api.json", "", "Use class: to merge Tailwind utilities, data: and aria: for native attributes. Block helpers capture Rails ERB.", "ui_button_to keeps Rails form, method and CSRF semantics. Each host application's lockfile pins its version.", "" ]
    components.each do |component|
      lines += [ "## #{component[:name]}", "", "```ruby", component[:signature], "```", "" ]
      component[:examples].each do |example|
        lines += [ "#{example[:title]}: #{example[:url]}", "", "```erb", example[:erb], "```", "" ]
      end
    end
    lines += [ "## Advanced styles", "", "Class helpers style custom markup; the application owns its behavior.", "Glass surfaces use glass_class; tw merges utility classes. Read https://github.com/lostcoords/ui#advanced-style-composition.", "" ]
    lines.concat(Lostcoords::Ui::Builders.all.map { |builder| "- `#{builder.signature}`" })
    lines.join("\n") + "\n"
  end
end
