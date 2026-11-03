module Lostcoords::Ui
  module LayoutHelper
    LAYOUT_GAPS = {
      tight: "gap-[var(--ui-space-tight,0.25rem)]",
      related: "gap-[var(--ui-space-related,0.5rem)]",
      heading: "gap-[var(--ui-space-heading,0.75rem)]",
      content: "gap-[var(--ui-space-content,1rem)]",
      inset: "gap-[var(--ui-space-inset,1.25rem)]",
      section: "gap-[var(--ui-space-section,2rem)]"
    }.freeze

    CONTAINER_SIZES = {
      page: "ui-container-page max-w-[var(--ui-page-max,75rem)]",
      reading: "max-w-[var(--ui-reading-measure,65ch)]",
      form: "max-w-[var(--ui-form-max,32rem)]"
    }.freeze

    def stack_class(gap: :content, extra: nil)
      gap = ui_option!(:gap, gap, LAYOUT_GAPS.keys)
      tw("flex min-w-0 flex-col", LAYOUT_GAPS.fetch(gap), extra)
    end

    def inline_class(gap: :related, extra: nil)
      gap = ui_option!(:gap, gap, LAYOUT_GAPS.keys)
      tw("flex min-w-0 flex-wrap items-center", LAYOUT_GAPS.fetch(gap), extra)
    end

    def container_class(size: :page, extra: nil)
      size = ui_option!(:size, size, CONTAINER_SIZES.keys)
      tw("mx-auto min-w-0 w-full", CONTAINER_SIZES.fetch(size), extra)
    end

    def section_header_class(extra: nil)
      inline_class(extra: tw("min-h-[var(--ui-section-header-height,2.75rem)] justify-between", extra))
    end

    def ui_stack(gap: :content, **attributes, &block)
      tag.div(**ui_attributes({ class: stack_class(gap: gap) }, attributes), &block)
    end

    def ui_inline(gap: :related, **attributes, &block)
      tag.div(**ui_attributes({ class: inline_class(gap: gap) }, attributes), &block)
    end

    def ui_container(size: :page, **attributes, &block)
      tag.div(**ui_attributes({ class: container_class(size: size) }, attributes), &block)
    end

    def ui_section(title:, level: 2, actions: nil, **attributes, &block)
      raise ArgumentError, "title must not be blank" if title.blank?

      tag.section(**ui_attributes({ class: stack_class(gap: :heading) }, attributes)) do
        heading = ui_heading(title, level: level, size: :section)
        action_content = actions.respond_to?(:call) ? capture(&actions) : actions
        header = tag.header(class: section_header_class) { safe_join([ heading, action_content ].compact) }
        safe_join([ header, ui_stack(&block) ])
      end
    end
  end
end
