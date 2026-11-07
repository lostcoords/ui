module Lostcoords::Ui
  module TypographyHelper
    HEADING_SIZES = { display: "text-display", title: "text-title", heading: "text-heading", subheading: "text-subheading" }.freeze
    TEXT_SIZES = { body: "text-body", small: "text-small", label: "text-label font-semibold", caption: "text-caption", eyebrow: "text-eyebrow lc-eyebrow" }.freeze
    TEXT_TONES = { default: "text-foreground", muted: "text-muted-foreground" }.freeze
    TEXT_ELEMENTS = %i[p span div label legend figcaption dt dd h1 h2 h3 h4 h5 h6].freeze
    KBD_BASE = "lc-kbd inline-flex items-center rounded-md bg-tile px-1.5 font-sans text-caption leading-5 whitespace-nowrap text-muted-foreground"
    KBD_NAMES = { "mod" => "Ctrl", "ctrl" => "Ctrl", "alt" => "Alt", "shift" => "Shift", "meta" => "Meta", "escape" => "Esc", "enter" => "↵",
                  "arrowup" => "↑", "arrowdown" => "↓", "arrowleft" => "←", "arrowright" => "→" }.freeze
    KBD_MODIFIERS = %w[mod ctrl alt shift meta].freeze

    def lc_heading_class(size: :heading, trim: false, extra: nil)
      size = lc_option!(:size, size, HEADING_SIZES.keys)
      lc_tw("lc-heading m-0 text-foreground", HEADING_SIZES.fetch(size), ("lc-trim" if trim), extra)
    end

    def lc_text_class(size: :body, tone: :default, trim: false, extra: nil)
      size = lc_option!(:size, size, TEXT_SIZES.keys)
      tone = lc_option!(:tone, tone, TEXT_TONES.keys)
      lc_tw("lc-text m-0", TEXT_SIZES.fetch(size), TEXT_TONES.fetch(tone), ("lc-trim" if trim), extra)
    end

    def lc_kbd_class(extra: nil)
      lc_tw(KBD_BASE, extra)
    end

    # anchor: true links the heading to itself, so readers can copy a link to it; it needs id:.
    # anchor: "section-id" links it to an element around it instead, such as its <section>.
    def lc_heading(content = nil, level: 2, size: :heading, trim: false, anchor: false, **attributes, &block)
      raise ArgumentError, "Invalid level: #{level.inspect}. Expected an integer from 1 to 6" unless (1..6).include?(level) && level.is_a?(Integer)

      target = anchor == true ? attributes[:id].to_s : anchor.presence&.to_s
      raise ArgumentError, "anchor: true needs an id" if anchor == true && target.blank?

      content = capture(&block) if block
      content = tag.a(content, href: "##{target}", class: "lc-anchor", data: { slot: "heading-anchor" }) if target
      tag.public_send("h#{level}", content, **lc_attributes({ class: lc_heading_class(size: size, trim: trim, extra: ("lc-anchor-target" if anchor == true)) }, attributes))
    end

    # as: picks the element, such as :span inside a row or :h3 for a heading set in a text role.
    def lc_text(content = nil, size: :body, tone: :default, trim: false, as: :p, **attributes, &block)
      tag.public_send(lc_option!(:as, as, TEXT_ELEMENTS), content, **lc_attributes({ class: lc_text_class(size: size, tone: tone, trim: trim) }, attributes), &block)
    end

    # A key hint, such as lc_kbd("mod+k"). "mod" renders Ctrl and reads ⌘ on Apple platforms once JS runs.
    def lc_kbd(keys, **attributes)
      lc_label!(keys, :keys)
      text = keys.split.map do |combo|
        *modifiers, key = combo.downcase.split(/\+(?!\z)/)
        names = modifiers.map { |modifier| KBD_MODIFIERS.include?(modifier) ? KBD_NAMES.fetch(modifier) : raise(ArgumentError, "Unknown modifier #{modifier.inspect} in #{keys.inspect}. Expected one of: #{KBD_MODIFIERS.join(', ')}") }
        # A symbol such as ? already implies Shift; a letter or digit keeps it.
        names.delete("Shift") if key.match?(/\A[^[:alnum:]]\z/)
        [ *names, KBD_NAMES.fetch(key) { key.length == 1 ? key.upcase : key.capitalize } ].join(" ")
      end.join(" / ")
      tag.kbd(text, **lc_attributes({ class: lc_kbd_class, data: { controller: "lc-kbd", lc_kbd_keys_value: keys } }, attributes))
    end

    # Data for the element a page-wide shortcut focuses (fields) or clicks (anything else):
    # lc_button "Search", data: lc_shortcut_data("mod+k"). Shortcuts without mod, ctrl or alt
    # don't fire while typing in a field; inside an open modal, only its own shortcuts do.
    def lc_shortcut_data(keys, data = {})
      lc_label!(keys, :keys)
      data = data.to_h.symbolize_keys
      data.merge(controller: [ data[:controller], "lc-shortcut" ].compact.join(" "), lc_shortcut_keys_value: keys)
    end
  end
end
