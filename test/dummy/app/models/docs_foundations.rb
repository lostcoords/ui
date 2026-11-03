require "lostcoords/ui/tokens"

module DocsFoundations
  Token = Data.define(:group, :name, :default, :controls)
  COLORS = Lostcoords::Ui::Tokens::COLORS.map do |name, description|
    Token.new("Colors", name, nil, description)
  end.freeze

  APPEARANCE = [
    Token.new("Shape and density", "--radius", "0.5rem", "Every corner radius; rounded-sm to rounded-3xl and rounded-pill scale from it"),
    Token.new("Shape and density", "--lc-density", "1", "Multiplies semantic spacing and control heights"),
    Token.new("Shape and density", "--lc-inset", "1.25rem", "Card, dialog and popover padding"),
    Token.new("Controls", "--lc-control-sm", "2rem", "Small control height (h-control-sm)"),
    Token.new("Controls", "--lc-control-md", "2.5rem", "Default control height (h-control-md)"),
    Token.new("Controls", "--lc-control-lg", "3rem", "Large control height (h-control-lg)"),
    Token.new("Controls", "--lc-input-hover", nil, "Hovered select background"),
    Token.new("Shadows", "--lc-shadow-sm", nil, "Small surface shadow"),
    Token.new("Shadows", "--lc-shadow", nil, "Default floating surface shadow"),
    Token.new("Shadows", "--lc-shadow-lg", nil, "Large floating surface shadow"),
    Token.new("Surfaces", "--lc-glass-fill", nil, "Translucent panel fill"),
    Token.new("Surfaces", "--lc-glass-edge", nil, "Translucent panel border"),
    Token.new("Overlays", "--lc-scrim", nil, "Dialog backdrop"),
    Token.new("Overlays", "--lc-scrim-sheet", nil, "Sheet backdrop"),
    Token.new("Motion", "--lc-sheet-duration", nil, "Sheet opening and closing time"),
    Token.new("Motion", "--lc-motion-control", nil, "Button interaction time")
  ].freeze

  TOKENS = [
    Token.new("Fonts", "--font-display", "var(--font-sans)", "Heading font family"),
    Token.new("Fonts", "--font-sans", "Tailwind's sans stack", "Body font family"),
    Token.new("Fonts", "--font-mono", "Tailwind's mono stack", "Code font family"),
    Token.new("Fonts", "--font-japanese", '"Hiragino Sans", "Yu Gothic", "YuGothic", "Meiryo", ui-sans-serif, system-ui, sans-serif', "Font family for Japanese text"),
    Token.new("Type roles", "--text-display", "2.25rem / 2.5rem", "Hero text (text-display)"),
    Token.new("Type roles", "--text-title", "1.875rem / 2.25rem", "Page title (text-title)"),
    Token.new("Type roles", "--text-heading", "1.25rem / 1.75rem", "Section title (text-heading)"),
    Token.new("Type roles", "--text-subheading", "1.125rem / 1.5rem", "Card and dialog title (text-subheading)"),
    Token.new("Type roles", "--text-body", "1rem / 1.5rem", "Body text (text-body)"),
    Token.new("Type roles", "--text-small", "0.875rem / 1.25rem", "Hints and secondary text (text-small)"),
    Token.new("Type roles", "--text-label", "0.875rem / 1.25rem", "Labels, buttons and menu items (text-label)"),
    Token.new("Type roles", "--text-caption", "0.75rem / 1rem", "Metadata and table headers (text-caption)"),
    Token.new("Spacing", "--spacing-tight", "0.25rem", "Icon and label (gap-tight)"),
    Token.new("Spacing", "--spacing-related", "0.5rem", "Label and control, button groups (gap-related)"),
    Token.new("Spacing", "--spacing-heading", "0.75rem", "Heading and its content (gap-heading)"),
    Token.new("Spacing", "--spacing-content", "1rem", "Blocks and fields (gap-content)"),
    Token.new("Spacing", "--spacing-inset", "var(--lc-inset)", "Container padding and the gaps between its blocks (p-inset)"),
    Token.new("Spacing", "--spacing-section", "2rem", "Page sections (gap-section)"),
    Token.new("Layout and reading", "--lc-gutter", "clamp(1rem, 3vw, 1.5rem)", "Page container side padding (px-gutter)"),
    Token.new("Layout and reading", "--container-page", "75rem", "Maximum page container width (max-w-page)"),
    Token.new("Layout and reading", "--container-form", "32rem", "Maximum form container width (max-w-form)"),
    Token.new("Layout and reading", "--container-reading", "65ch", "Maximum reading width (max-w-reading)"),
    Token.new("Layout and reading", "--lc-reading-size", "1rem", "Reading text size"),
    Token.new("Layout and reading", "--lc-reading-leading", "1.75", "Reading text line height"),
    Token.new("Layout and reading", "--lc-reading-flow", "1.25em", "Space between reading blocks"),
    Token.new("Layout and reading", "--lc-reading-heading-leading", "1.25", "Reading heading line height. Japanese headings use 1.4.")
  ].freeze

  OVERRIDE = <<~CSS.strip.freeze
    .report-page {
    	--primary: oklch(46% 0.14 155);
    	--lc-inset: 1.5rem;
    	--lc-density: 1.125;
    	--text-title: 2rem;
    }
  CSS
end
