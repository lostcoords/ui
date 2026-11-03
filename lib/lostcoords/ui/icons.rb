require "json"
require "nokogiri"

module Lostcoords::Ui
  module Icons
    TEMPLATES = {}
    LOCK = Mutex.new

    def self.fetch(name, variant)
      LOCK.synchronize do
        @catalog ||= JSON.parse(File.read(Lostcoords::Ui.root.join("vendor/heroicons/icons.json")), freeze: true).fetch("icons")
        source = @catalog.fetch(variant.to_s).fetch(name.to_s)
        template = TEMPLATES[source] ||= begin
          document = Nokogiri::XML(source) { |config| config.strict.nonet }
          document.xpath("//text()[normalize-space(.) = '']").remove
          document
        end
        template.dup.root
      end
    rescue KeyError
      raise ArgumentError, "Unknown Heroicon #{name.inspect} with variant #{variant.inspect}"
    end
  end
end
