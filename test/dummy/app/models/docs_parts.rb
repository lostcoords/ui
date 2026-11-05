require "prism"

# Reads the builders that compound helpers yield from lib/lostcoords/ui/parts.rb, so the API reference
# lists card.header, dialog.footer and the rest next to the helper that yields them.
module DocsParts
  PATH = File.expand_path("../../../../lib/lostcoords/ui/parts.rb", __dir__)
  # Builder class => [ helper that yields it, block variable the examples use ]
  OWNERS = {
    "Card" => [ :lc_card, "card" ], "Dialog" => [ :lc_dialog, "dialog" ], "Alert" => [ :lc_alert, "alert" ],
    "Tabs" => [ :lc_tabs, "tabs" ], "NavList" => [ :lc_nav_list, "nav" ], "DescriptionList" => [ :lc_description_list, "list" ]
  }.freeze

  Part = Data.define(:receiver, :name, :parameters) do
    def signature = "#{receiver}.#{name}(#{parameters})"
    # The bare method signature, which ShowcaseHelper#showcase_parameters parses.
    def definition = "#{name}(#{parameters})"
  end

  def self.for(component) = all.fetch(component, [])

  def self.all
    @all ||= Prism.parse_file(PATH).value.statements.body.first.body.body.first.body.body.grep(Prism::ClassNode).each_with_object({}) do |node, parts|
      owner, receiver = OWNERS[node.constant_path.slice]
      next unless owner

      parts[owner] = public_methods_in(node).map { |method| Part.new(receiver, method.name, method.parameters&.slice) }
    end
  end

  def self.public_methods_in(node)
    visible = true
    node.body.body.filter_map do |child|
      visible = false if child.is_a?(Prism::CallNode) && %i[private protected].include?(child.name) && child.arguments.nil?
      child if visible && child.is_a?(Prism::DefNode) && child.receiver.nil? && child.name != :initialize
    end
  end
end
