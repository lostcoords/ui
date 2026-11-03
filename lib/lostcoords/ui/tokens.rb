require_relative "version"

module Lostcoords::Ui
  module Tokens
    THEME_PATH = File.expand_path("../../../app/assets/tailwind/lostcoords/ui/theme.css", __dir__)
    DECLARATION = /(?<![\w-])(--[\w-]+)\s*:/
    COLORS = {
      "--background" => "Page background",
      "--foreground" => "Main text and headings",
      "--card" => "Cards and grouped content",
      "--card-foreground" => "Text on cards",
      "--popover" => "Menus, popovers and dialogs",
      "--popover-foreground" => "Text on menus, popovers and dialogs",
      "--primary" => "Primary actions, links, selected states and keyboard focus",
      "--primary-foreground" => "Text and icons on a solid primary background",
      "--secondary" => "Secondary buttons",
      "--secondary-foreground" => "Text on secondary buttons",
      "--muted" => "Subtle backgrounds: badges, code, skeletons, table headers",
      "--muted-foreground" => "Secondary text, hints and placeholders",
      "--accent" => "Hovered rows, menu items and inline code",
      "--accent-foreground" => "Text on accent backgrounds",
      "--destructive" => "Errors and destructive actions",
      "--success" => "Successful actions and positive feedback",
      "--warning" => "Warnings and items needing attention",
      "--border" => "Dividers and outlines",
      "--input" => "Input and toggle fills",
      "--ring" => "Keyboard focus ring; unset, it follows --primary"
    }.freeze
    FONTS = %w[--font-sans --font-display --font-mono --font-japanese].freeze

    def self.names
      (COLORS.keys + FONTS).sort
    end
  end

  TOKENS = Tokens.names.freeze
end
