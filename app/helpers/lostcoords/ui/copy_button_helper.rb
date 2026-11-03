module Lostcoords::Ui
  module CopyButtonHelper
    def lc_copy_button(label = nil, value: nil, source: nil, copied_label: nil, error_label: nil, reset_after: 2000, icon_only: false, variant: :secondary, size: :base, **attributes)
      raise ArgumentError, "Provide either value: or source:" unless value.nil? != source.nil?
      raise ArgumentError, "source: must be a nonblank element ID" if !source.nil? && source.blank?
      raise ArgumentError, "reset_after: must be a positive number of milliseconds" unless reset_after.is_a?(Numeric) && reset_after.finite? && reset_after.positive?

      label ||= lc_t("lostcoords.ui.copy_button.label")
      copied_label ||= lc_t("lostcoords.ui.copy_button.copied")
      error_label ||= lc_t("lostcoords.ui.copy_button.retry")
      size = lc_option!(:size, size, %i[sm base lg])
      defaults = {
        class: lc_tw("inline-grid", ({ sm: "size-11 p-0", base: "size-12 p-0", lg: "size-14 p-0" }.fetch(size) if icon_only)),
        aria: { label: label }, data: { action: "ui-copy#copy", ui_copy_target: "button" }
      }
      button_attributes = lc_attributes(defaults, attributes).merge(type: "button")
      raise ArgumentError, "A copy button requires a nonblank accessible label" if button_attributes.dig(:aria, :label).blank?

      tag.span(class: "ui-copy", data: { controller: "ui-copy", state: "idle", ui_copy_value_value: value, ui_copy_source_value: source, ui_copy_reset_after_value: reset_after }) do
        safe_join([
          lc_button(variant: variant, size: size, **button_attributes) do
            safe_join([
              lc_copy_content(:idle, "document-duplicate", label, icon_only),
              lc_copy_content(:copied, "check", copied_label, icon_only),
              lc_copy_content(:error, "arrow-path", error_label, icon_only)
            ])
          end,
          tag.span(class: "sr-only", role: "status", aria: { atomic: true }, data: { ui_copy_target: "status", copied: copied_label, error: lc_t("lostcoords.ui.copy_button.error") })
        ])
      end
    end

    private
      def lc_copy_content(state, icon, label, icon_only)
        tag.span(class: "ui-copy-content", aria: { hidden: true }, data: { copy_state: state, icon: ("inline-start" unless icon_only) }) do
          safe_join([ lc_icon(icon, options: { "aria-hidden": true }), (tag.span(label) unless icon_only) ].compact)
        end
      end
  end
end
