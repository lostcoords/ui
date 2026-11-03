require "prism"
require_relative "version"

module Lostcoords::Ui
  module Builders
    HELPERS = File.expand_path("../../../app/helpers/lostcoords/ui", __dir__)

    Builder = Data.define(:helper, :name, :parameters, :path, :line) do
      def signature = parameters ? "#{name}(#{parameters})" : name.to_s

      def component?
        !name.to_s.end_with?("_class") &&
          !%i[lc_tw lc_sheet_data lc_alert_icon].include?(name) &&
          helper != "EmojiPickerHelper"
      end
    end

    def self.all
      definitions.reject(&:component?)
    end

    def self.definitions
      Dir["#{HELPERS}/*_helper.rb"].sort.flat_map { |path| public_instance_methods_in(path) }
    end

    def self.markdown
      all.map { |builder| "- `#{builder.signature}` (#{builder.helper})" }.join("\n")
    end

    def self.public_instance_methods_in(path)
      namespace = Prism.parse_file(path).value.statements.body.grep(Prism::ModuleNode).first
      helper = namespace.body.body.first
      visible = true
      helper.body.body.filter_map do |node|
        visible = false if node.is_a?(Prism::CallNode) && node.name == :private && node.arguments.nil?
        next unless visible && node.is_a?(Prism::DefNode) && node.receiver.nil?

        Builder.new(helper.constant_path.slice, node.name, node.parameters&.slice, path, node.location.start_line)
      end
    end
  end
end
