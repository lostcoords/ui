require_relative "version"

module Lostcoords::Ui
  module Tokens
    THEME_PATH = File.expand_path("../../../app/assets/tailwind/lostcoords/ui/theme.css", __dir__)
    DECLARATION = /(?<![\w-])(--[\w-]+)\s*:/

    def self.names
      File.read(THEME_PATH).scan(DECLARATION).flatten.uniq.sort
    end
  end

  TOKENS = Tokens.names.freeze
end
