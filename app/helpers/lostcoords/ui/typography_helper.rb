module Lostcoords::Ui
  module TypographyHelper
    HEADING_SIZES = { display: "text-display", title: "text-title", heading: "text-heading", subheading: "text-subheading" }.freeze
    TEXT_SIZES = { body: "text-body", small: "text-small", label: "text-label", caption: "text-caption" }.freeze
    TEXT_TONES = { default: "text-foreground", muted: "text-muted-foreground" }.freeze

    def lc_heading_class(size: :heading, trim: false, extra: nil)
      size = lc_option!(:size, size, HEADING_SIZES.keys)
      lc_tw("lc-heading m-0 text-foreground", HEADING_SIZES.fetch(size), ("lc-trim" if trim), extra)
    end

    def lc_text_class(size: :body, tone: :default, trim: false, extra: nil)
      size = lc_option!(:size, size, TEXT_SIZES.keys)
      tone = lc_option!(:tone, tone, TEXT_TONES.keys)
      lc_tw("lc-text m-0", TEXT_SIZES.fetch(size), TEXT_TONES.fetch(tone), ("lc-trim" if trim), extra)
    end

    def lc_heading(content = nil, level: 2, size: :heading, trim: false, **attributes, &block)
      raise ArgumentError, "Invalid level: #{level.inspect}. Expected an integer from 1 to 6" unless (1..6).include?(level) && level.is_a?(Integer)

      tag.public_send("h#{level}", content, **lc_attributes({ class: lc_heading_class(size: size, trim: trim) }, attributes), &block)
    end

    def lc_text(content = nil, size: :body, tone: :default, trim: false, **attributes, &block)
      tag.p(content, **lc_attributes({ class: lc_text_class(size: size, tone: tone, trim: trim) }, attributes), &block)
    end
  end
end
