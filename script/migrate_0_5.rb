#!/usr/bin/env ruby
# Rewrites an application from lostcoords-ui 0.4 to 0.5 names.
#
#   ruby script/migrate_0_5.rb path/to/app            # report files that would change
#   ruby script/migrate_0_5.rb path/to/app --write    # rewrite them
#
# Renames theme colors to shadcn names, prefixes library classes, custom
# properties and Stimulus identifiers with lc-, and renames size and tone
# options. Review the diff afterwards: `bg-surface` becomes `bg-muted`, and a
# card-like surface may want `bg-card`.

require "find"

module Migration05
  EXTENSIONS = %w[.rb .erb .css .js .md .html .yml].freeze
  SKIP = %r{/(?:node_modules|vendor|tmp|log|builds|\.git|\.jj|pkg)/}

  CONTROLLERS = {
    "modal" => "lc-dialog",
    "sheet" => "lc-sheet",
    "toast" => "lc-toast",
    "disclosure" => "lc-collapsible",
    "row-menu" => "lc-menu",
    "confirm-dialog" => "lc-confirm-dialog",
    "emoji-picker" => "lc-emoji-picker",
    "ui-copy" => "lc-copy",
    "ui-code-block" => "lc-code-block",
    "ui-popover" => "lc-popover",
    "ui-selection" => "lc-selection",
    "ui-toggle" => "lc-toggle"
  }.freeze

  COMPONENT_VARIABLES = %w[
    button card field avatar icon-badge code-block table-rule scroll-fade emoji focus-halo
    anchored scroll-lock sheet dialog pop
  ].freeze

  RULES = [
    # Stimulus identifiers, data attributes and actions.
    *CONTROLLERS.flat_map do |old, new|
      underscore_old = old.tr("-", "_")
      underscore_new = new.tr("-", "_")
      [
        [ /(?<![\w.\/-])#{Regexp.escape(old)}(?=#[a-zA-Z]|-target|-[a-z-]+-value|:[a-z]|["'~\]]|\s+\w+#|"\s)/, new ],
        [ /(?<![\w.\/-])#{Regexp.escape(underscore_old)}_(?=target|[a-z_]+_value)/, "#{underscore_new}_" ],
        [ /(?<![\w-])data-#{Regexp.escape(old)}-/, "data-#{new}-" ]
      ]
    end,

    # Library classes.
    [ /(?<![\w-])app-dialog/, "lc-dialog" ],
    [ /(?<![\w-])context-dialog/, "lc-dialog-context" ],
    [ /(?<![\w-])disclosure-animated/, "lc-collapsible" ],
    [ /(?<![\w-])row-menu__/, "lc-menu__" ],
    [ /(?<![\w-])popover-shell/, "lc-popover-shell" ],
    [ /(?<![\w-])popover-pop/, "lc-popover-pop" ],
    [ /(?<![\w-])select-control/, "lc-select" ],
    [ /(?<![\w-])scroll-fade-x/, "lc-scroll-fade-x" ],
    [ /(?<![\w-])icon-badge(?![\w])/, "lc-icon-badge" ],
    [ /(?<=[."\s_])avatar-(stack__row|stack|ring)(?![\w-])/, 'lc-avatar-\1' ],
    [ /(?<=\[&_\.|\[&>\.|^\.|\s\.|,\.|\(\.)avatar(?![\w-])/, "lc-avatar" ],
    [ /(?<=\.)glass(?![\w-])/, "lc-glass" ],
    [ /(?<=\.)sheet(?=--anchored|[\s\[:{,)])/, "lc-sheet" ],
    [ /(?<![\w-])sheet--anchored/, "lc-sheet--anchored" ],
    [ /(?<![\w\/-])ui-(?!sans-serif|serif|monospace|rounded)(?=[a-z])/, "lc-" ],
    [ /(?<![\w\/.-])ui_(?=[a-z])/, "lc_" ],

    # Theme colors.
    [ /--surface-hover(?![\w-])/, "--accent" ],
    [ /(?<![\w-])((?:[a-z-]+:)*(?:bg|text|border|ring|outline|fill|from|to|via))-surface-hover(?![\w-])/, '\1-accent' ],
    [ /--control-hover-bg(?![\w-])/, "--lc-input-hover" ],
    [ /--control-bg(?![\w-])/, "--input" ],
    [ /--button-secondary-bg(?![\w-])/, "--secondary" ],
    [ /--muted(?![\w-])/, "--muted-foreground" ],
    [ /(?<![\w-])((?:[a-z-]+:)*(?:text|border|fill|stroke|decoration|outline))-muted(?![\w-])/, '\1-muted-foreground' ],
    [ /--surface(?![\w-])/, "--muted" ],
    [ /(?<![\w-])((?:[a-z-]+:)*(?:bg|text|border|ring|outline|fill|from|to|via|divide))-surface(?![\w-])/, '\1-muted' ],
    [ /(?<![a-z])on-primary(?![\w-])/, "primary-foreground" ],
    [ /(?<![a-z])danger/, "destructive" ],
    [ /(?<![a-z])Danger/, "Destructive" ],

    # Fonts.
    [ /--f-body(?![\w-])/, "--font-sans" ],
    [ /--f-display(?![\w-])/, "--font-display" ],
    [ /--f-mono(?![\w-])/, "--font-mono" ],
    [ /--f-japanese(?![\w-])/, "--font-japanese" ],
    [ /--font-body(?![\w-])/, "--font-sans" ],
    [ /(?<![\w-])font-body(?![\w-])/, "font-sans" ],

    # Theme settings and component variables.
    [ /--scrim(?=[\s,;)-])/, "--lc-scrim" ],
    [ /(?<![\w-])--shadow(-sm|-lg)?(?![\w-])/, '--lc-shadow\1' ],
    [ /\(--shadow(-sm|-lg)?\)/, '(--lc-shadow\1)' ],
    [ /--_glass-fill/, "--_lc-glass-fill" ],
    [ /(?<![\w-])--glass-/, "--lc-glass-" ],
    [ /--(?:ui-)?press-scale/, "--lc-press-scale" ],
    [ /--ui-motion-/, "--lc-motion-" ],
    [ /--ease-out-expo/, "--lc-ease-out-expo" ],
    [ /--ease-sheet/, "--lc-ease-sheet" ],
    [ /(?<![\w-])--ease-out(?![\w-])/, "--lc-ease-out" ],
    [ /(?<![\w-])--(#{COMPONENT_VARIABLES.join('|')})(?=[-\w])/, '--lc-\1' ],
    [ /--z-index-prompt/, "--lc-z-sheet" ],
    [ /(?<![\w-])z-nav-popover/, "z-(--lc-z-popover)" ],
    [ /--ui-/, "--lc-" ],

    # Options.
    [ /size: :base(?![\w])/, "size: :md" ],
    [ /(lc_heading[^\n]*?size: :)page(?![\w])/, '\1title' ],
    [ /(lc_heading[^\n]*?size: :)section(?![\w])/, '\1heading' ],
    [ /(lc_heading[^\n]*?size: :)card(?![\w])/, '\1subheading' ]
  ].freeze

  CLASS_ATTRIBUTE = /(\bclass(?:=|:\s*)["'])([^"']*)/
  CONTROLLER_ATTRIBUTE = /(\bdata-controller=["']|\bcontroller:\s*["'])([^"']*)/
  BARE_CLASSES = /(?<![\w-])(glass|squircle|press|avatar)(?![\w-])/

  # Already-migrated code uses the new names, and a second pass would turn
  # --muted (the old --surface) into --muted-foreground.
  def self.migrated?(source)
    source.include?("muted-foreground") || source.match?(/(?<![\w-])lc-(?:dialog|menu|copy|sheet)[#"' -]/)
  end

  def self.rewrite(source)
    source = source.gsub(CLASS_ATTRIBUTE) { "#{$1}#{$2.gsub(BARE_CLASSES, 'lc-\\1')}" }
    source = source.gsub(CONTROLLER_ATTRIBUTE) do
      "#{$1}#{$2.split(/(\s+)/).map { |token| CONTROLLERS.fetch(token, token) }.join}"
    end
    RULES.reduce(source) { |text, (pattern, replacement)| text.gsub(pattern, replacement) }
  end

  def self.files(roots)
    roots.flat_map do |root|
      next [ root ] if File.file?(root)

      Find.find(root).select do |path|
        File.file?(path) && EXTENSIONS.include?(File.extname(path)) && !path.delete_prefix(root).match?(SKIP)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  write = ARGV.delete("--write")
  abort "usage: ruby script/migrate_0_5.rb PATH... [--write]" if ARGV.empty?

  Migration05.files(ARGV).each do |path|
    source = File.read(path)
    if Migration05.migrated?(source)
      puts "skipped #{path}: it already uses 0.5 names"
      next
    end

    updated = Migration05.rewrite(source)
    next if updated == source

    File.write(path, updated) if write
    puts "#{write ? 'rewrote' : 'would rewrite'} #{path}"
  end
end
