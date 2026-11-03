require "open3"
require "tmpdir"
require_relative "version"

module Lostcoords::Ui
  TOKENS = %w[
    --animate-alert-in --berry --color-accent --color-berry --color-berry-soft --color-danger
    --color-danger-soft --color-gold --color-gold-soft --color-ink --color-ink-2 --color-ink-3
    --color-ink-on-accent --color-leaf --color-leaf-soft --color-paper --color-paper-2 --color-paper-3
    --color-sky --color-sky-deep --color-sky-soft --ease-out-expo --ease-sheet --focus-halo
    --font-body --glass-bar-edge --glass-edge --glass-fill --glass-hud-fill --glass-hud-ink
    --glass-hud-shadow --glass-hud-solid --glass-rim --glass-shadow --hairline --ink
    --ink-2 --ink-3 --ink-on-accent --leaf-soft --paper --paper-2
    --paper-3 --pill-depth --pill-light --pill-rim --pill-surface --scrim
    --scrim-sheet --scrim-soft --shadow --sheet-duration --sheet-offscreen --sky
    --sky-soft --z-index-art --z-index-nav-popover --z-index-prompt
  ].freeze

  module Tokens
    ROOT = File.expand_path("../../..", __dir__)
    DECLARATION = /(?<![\w-])(--[\w-]+)\s*:/

    def self.missing_from(css)
      defined = css.scan(DECLARATION).flatten
      TOKENS - defined
    end

    # The custom properties the gem's compiled CSS and JS read without a fallback that neither the gem nor
    # Tailwind's default theme supply. Builds the gem's stylesheet and sources with the host's @theme and
    # @custom-variant rules (its @theme made non-inline, so theme utilities keep their --color-* names) and again
    # without them. A property the gem sets somewhere and the host also defines is still the host's: the gem only
    # overrides it in places.
    def self.derive(host_tokens_path, tailwindcss:)
      host_css = File.read(host_tokens_path)
      host_at_rules = theme_at_rules(host_css).gsub("@theme inline", "@theme")
      with_host, without_host = [ host_at_rules, "" ].map { |at_rules| build(at_rules, tailwindcss) }

      rest = split_theme(with_host).last
      default_theme = split_theme(without_host).first.scan(DECLARATION).flatten
      gem_defined = rest.scan(DECLARATION).flatten + javascript.scan(/setProperty\(\s*["'](--[\w-]+)/).flatten
      required = rest.scan(/var\(\s*(--[\w-]+)\s*\)/).flatten + javascript.scan(/getPropertyValue\(\s*["'](--[\w-]+)/).flatten

      internal = gem_defined - host_css.scan(DECLARATION).flatten
      (required.uniq - default_theme - internal).reject { |name| name.start_with?("--tw-") }.sort
    end

    def self.build(host_at_rules, tailwindcss)
      Dir.mktmpdir do |dir|
        File.write("#{dir}/entry.css", <<~CSS)
          @layer theme, base, layout, components, modules, utilities;
          @import "tailwindcss/theme.css" layer(theme);
          @import "tailwindcss/utilities.css" layer(utilities) source(none);
          #{host_at_rules}
          @import "#{ROOT}/app/assets/tailwind/lostcoords/ui/ui.css";
        CSS
        _, error, status = Open3.capture3(tailwindcss, "-i", "#{dir}/entry.css", "-o", "#{dir}/out.css")
        raise "tailwindcss failed: #{error}" unless status.success?

        File.read("#{dir}/out.css")
      end
    end

    def self.split_theme(css)
      start = css.index("@layer theme {") or return [ "", css ]
      depth, finish = 0, start
      css[start..].each_char.with_index do |char, index|
        depth += 1 if char == "{"
        depth -= 1 if char == "}"
        (finish = start + index) && break if char == "}" && depth.zero?
      end
      [ css[start..finish], css[0...start] + css[(finish + 1)..] ]
    end

    def self.theme_at_rules(css)
      css = css.gsub(%r{/\*.*?\*/}m, "")
      statements, depth, current = [], 0, +""
      css.each_char do |char|
        current << char
        depth += 1 if char == "{"
        depth -= 1 if char == "}"
        next unless depth.zero? && (char == "}" || char == ";")

        statements << current.strip if current.strip.start_with?("@theme", "@custom-variant")
        current = +""
      end
      statements.join("\n")
    end

    def self.javascript
      Dir["#{ROOT}/app/javascript/**/*.js"].sort.map { |path| File.read(path) }.join("\n")
    end
  end
end
