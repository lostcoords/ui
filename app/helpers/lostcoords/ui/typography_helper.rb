module Lostcoords::Ui
  module TypographyHelper
    HEADING_SIZES = { page: "ui-heading-page", section: "ui-heading-section", card: "ui-heading-card" }.freeze
    TEXT_SIZES = { body: "ui-text-body", small: "ui-text-small", caption: "ui-text-caption" }.freeze
    TEXT_TONES = { default: "text-ink", muted: "text-ink-2", subtle: "text-ink-3" }.freeze

    def heading_class(size: :section, extra: nil)
      size = ui_option!(:size, size, HEADING_SIZES.keys)
      tw("ui-heading m-0 text-ink", HEADING_SIZES.fetch(size), extra)
    end

    def text_class(size: :body, tone: :default, extra: nil)
      size = ui_option!(:size, size, TEXT_SIZES.keys)
      tone = ui_option!(:tone, tone, TEXT_TONES.keys)
      tw("ui-text m-0", TEXT_SIZES.fetch(size), TEXT_TONES.fetch(tone), extra)
    end

    def ui_heading(content = nil, level: 2, size: :section, **attributes, &block)
      raise ArgumentError, "Invalid level: #{level.inspect}. Expected an integer from 1 to 6" unless (1..6).include?(level) && level.is_a?(Integer)

      tag.public_send("h#{level}", content, **ui_attributes({ class: heading_class(size: size) }, attributes), &block)
    end

    def ui_text(content = nil, size: :body, tone: :default, **attributes, &block)
      tag.p(content, **ui_attributes({ class: text_class(size: size, tone: tone) }, attributes), &block)
    end
  end
end
