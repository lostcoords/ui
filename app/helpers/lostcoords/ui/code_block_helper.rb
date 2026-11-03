module Lostcoords::Ui
  module CodeBlockHelper
    def lc_code_block(source, id:, language: nil, title: nil, label: nil, max_lines: 10, **attributes, &block)
      lc_label!(id, :id)
      lc_label!(title, :title) unless title.nil?
      label ||= lc_t("lostcoords.ui.code_block.label")
      lc_label!(label, :label)
      raise ArgumentError, "max_lines must be a positive integer or nil" unless max_lines.nil? || (max_lines.is_a?(Integer) && max_lines.positive?)

      source = String.new(source.to_s)
      content = block ? capture(source, &block) : source
      truncated = !max_lines.nil? && source.lines.size > max_lines
      defaults = {
        id: id, class: "lc-code-block group/code-block relative min-h-15 overflow-hidden rounded-2xl bg-muted",
        data: { controller: "lc-code-block", action: "lc-copy:error->lc-code-block#copyFailed" }
      }
      render "lostcoords/ui/components/lc_code_block", id: id, language: language, title: title, label: label,
        content: content, truncated: truncated, max_lines: max_lines,
        attributes: lc_attributes(defaults, attributes)
    end
  end
end
