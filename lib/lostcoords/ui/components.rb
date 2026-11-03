require_relative "builders"

module Lostcoords::Ui
  module Components
    def self.all
      Builders.definitions.select { |builder| builder.name.to_s.start_with?("ui_") }
    end

    def self.markdown
      all.map { |component| "- `#{component.signature}`" }.join("\n")
    end
  end
end
