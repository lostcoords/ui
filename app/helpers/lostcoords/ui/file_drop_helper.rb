module Lostcoords::Ui
  module FileDropHelper
    FILE_DROP =
      "grid min-h-45 cursor-pointer place-items-center content-center gap-2 rounded-2xl border-2 border-dashed border-border bg-muted p-4 text-center " \
      "transition-[background-color,border-color,box-shadow] duration-150 ease-out hover:border-primary hover:bg-accent hover:shadow-(--lc-shadow-sm) sm:p-6"

    def lc_file_drop_class(extra: nil)
      lc_tw(FILE_DROP, extra)
    end

    # A dashed drop zone: a label around a visually hidden file input, so a click or a dropped file reaches the
    # input. name: builds the input with accept:, multiple: and input: attributes, such as a controller target;
    # a block renders your own input instead (form.file_drop passes the form's), and must give it class "sr-only".
    # button: adds a decorative button inside the label, which the label already names.
    def lc_file_drop(name: nil, title:, hint: nil, button: nil, icon: "arrow-up-tray", accept: nil, multiple: false, input: {}, **attributes, &block)
      lc_label!(title, :title)
      raise ArgumentError, "Pass name: or a block that renders the file input, not both" if name && block
      raise ArgumentError, "lc_file_drop needs name: or a block that renders the file input" unless name || block

      field = block ? capture(&block) : file_field_tag(name, **lc_attributes({ class: "sr-only", accept: accept, multiple: multiple }, input))
      tag.label(**lc_attributes({ class: lc_file_drop_class, data: { slot: "file-drop" } }, attributes)) do
        safe_join([
          lc_icon_badge(icon: icon, size: :lg, shape: :circle, tone: :primary, class: "mb-2", aria: { hidden: true }),
          tag.span(title, class: lc_heading_class(size: :subheading), data: { slot: "file-drop-title" }),
          (lc_text(hint, as: :span, size: :small, tone: :muted, data: { slot: "file-drop-hint" }) if hint.present?),
          (lc_button(button, as: :span, size: :sm, class: "mt-2 pointer-events-none", aria: { hidden: true }) if button.present?),
          field
        ].compact)
      end
    end
  end
end
