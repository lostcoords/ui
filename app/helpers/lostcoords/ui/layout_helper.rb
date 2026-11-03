module Lostcoords::Ui
  module LayoutHelper
    # Space between things belongs to these helpers; components never set outer margin.
    LAYOUT_GAPS = {
      tight: "gap-tight",
      related: "gap-related",
      heading: "gap-heading",
      content: "gap-content",
      inset: "gap-inset",
      section: "gap-section"
    }.freeze

    CONTAINER_SIZES = {
      page: "lc-container-page max-w-page",
      reading: "max-w-reading",
      form: "max-w-form"
    }.freeze

    def lc_stack_class(gap: :content, extra: nil)
      gap = lc_option!(:gap, gap, LAYOUT_GAPS.keys)
      lc_tw("flex min-w-0 flex-col", LAYOUT_GAPS.fetch(gap), extra)
    end

    def lc_inline_class(gap: :related, extra: nil)
      gap = lc_option!(:gap, gap, LAYOUT_GAPS.keys)
      lc_tw("flex min-w-0 flex-wrap items-center", LAYOUT_GAPS.fetch(gap), extra)
    end

    def lc_container_class(size: :page, extra: nil)
      size = lc_option!(:size, size, CONTAINER_SIZES.keys)
      lc_tw("mx-auto min-w-0 w-full", CONTAINER_SIZES.fetch(size), extra)
    end

    # The header keeps a control's height, so a section with actions and one without line up.
    def lc_section_header_class(extra: nil)
      lc_inline_class(extra: lc_tw("min-h-control-md justify-between", extra))
    end

    def lc_stack(gap: :content, **attributes, &block)
      tag.div(**lc_attributes({ class: lc_stack_class(gap: gap) }, attributes), &block)
    end

    def lc_inline(gap: :related, **attributes, &block)
      tag.div(**lc_attributes({ class: lc_inline_class(gap: gap) }, attributes), &block)
    end

    def lc_container(size: :page, **attributes, &block)
      tag.div(**lc_attributes({ class: lc_container_class(size: size) }, attributes), &block)
    end

    def lc_section(title:, level: 2, actions: nil, **attributes, &block)
      raise ArgumentError, "title must not be blank" if title.blank?

      tag.section(**lc_attributes({ class: lc_stack_class(gap: :heading) }, attributes)) do
        heading = lc_heading(title, level: level, size: :heading)
        action_content = actions.respond_to?(:call) ? capture(&actions) : actions
        header = tag.header(class: lc_section_header_class) { safe_join([ heading, action_content ].compact) }
        safe_join([ header, lc_stack(&block) ])
      end
    end
  end
end
