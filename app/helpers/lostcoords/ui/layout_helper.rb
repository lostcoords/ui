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

    LAYOUT_ELEMENTS = %i[div section article aside header footer nav main form fieldset ul ol li].freeze

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

    # as: picks the element, such as :section, :ul or :form, for layout that carries meaning.
    def lc_stack(gap: :content, as: :div, **attributes, &block)
      tag.public_send(lc_option!(:as, as, LAYOUT_ELEMENTS), **lc_attributes({ class: lc_stack_class(gap: gap) }, attributes), &block)
    end

    def lc_inline(gap: :related, as: :div, **attributes, &block)
      tag.public_send(lc_option!(:as, as, LAYOUT_ELEMENTS), **lc_attributes({ class: lc_inline_class(gap: gap) }, attributes), &block)
    end

    def lc_container(size: :page, **attributes, &block)
      tag.div(**lc_attributes({ class: lc_container_class(size: size) }, attributes), &block)
    end

    # anchor: true links the heading to the section's id:, for pages readers link into.
    def lc_section(title:, level: 2, actions: nil, anchor: false, **attributes, &block)
      raise ArgumentError, "title must not be blank" if title.blank?
      raise ArgumentError, "anchor: true needs an id" if anchor && attributes[:id].blank?

      tag.section(**lc_attributes({ class: lc_stack_class(gap: :heading, extra: ("lc-anchor-target" if anchor)) }, attributes)) do
        heading = lc_heading(title, level: level, size: :heading, anchor: (attributes[:id] if anchor))
        action_content = actions.respond_to?(:call) ? capture(&actions) : actions
        header = lc_section_header { safe_join([ heading, action_content ].compact) }
        safe_join([ header, lc_stack(&block) ])
      end
    end

    # The heading row of a section whose heading needs more than a title, such as a lede under it.
    def lc_section_header(as: :header, **attributes, &block)
      tag.public_send(lc_option!(:as, as, %i[header div]), **lc_attributes({ class: lc_section_header_class }, attributes), &block)
    end
  end
end
