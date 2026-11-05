module Lostcoords::Ui
  module RenderAttributesHelper
    private
      # required: attributes the component needs to work, merged last so a caller can't override them.
      def lc_attributes(defaults, attributes, required = nil)
        return lc_attributes(lc_attributes(defaults, attributes), required) if required

        defaults = lc_normalize_attributes(defaults)
        attributes = lc_normalize_attributes(attributes)
        merged = defaults.merge(attributes)
        merged[:class] = lc_tw(CGI.unescape_html(class_names(defaults[:class], attributes[:class]))) if defaults.key?(:class) || attributes.key?(:class)
        %i[data aria].each do |key|
          next unless defaults[key].is_a?(Hash) && attributes[key].is_a?(Hash)

          merged[key] = defaults[key].merge(attributes[key])
        end
        %i[controller action].each do |key|
          next unless defaults.dig(:data, key)

          merged[:data] ||= {}
          merged[:data][key] = [ defaults[:data][key], attributes.dig(:data, key) ].join(" ").split.uniq.join(" ")
        end
        merged
      end

      def lc_normalize_attributes(attributes)
        normalized = attributes.deep_symbolize_keys
        %i[data aria].each do |prefix|
          values = normalized[prefix]
          values = values.transform_keys { |key| key.to_s.tr("-", "_").to_sym } if values.is_a?(Hash)
          normalized.keys.each do |key|
            next unless key.to_s.start_with?("#{prefix}-")

            values ||= {}
            values[key.to_s.delete_prefix("#{prefix}-").tr("-", "_").to_sym] = normalized.delete(key)
          end
          normalized[prefix] = values if values
        end
        # Rails renders popover: true as popover="true", which browsers read as manual: no light dismiss.
        normalized[:popover] = "auto" if normalized[:popover] == true
        normalized
      end

      def lc_label!(value, name)
        raise ArgumentError, "#{name} must not be blank" if value.blank?
      end

      # The hint and error paragraphs under a field or choice group. With an id, controls can point
      # aria-describedby at them.
      def lc_field_messages(id, hint, errors)
        [
          (tag.p(hint, id: ("#{id}-hint" if id), class: "m-0 text-small text-muted-foreground", data: { slot: "field-description" }) if hint.present?),
          (tag.p(safe_join(errors, tag.br), id: ("#{id}-error" if id), class: "m-0 text-small text-destructive", role: "alert", data: { slot: "field-error" }) if errors.any?)
        ].compact
      end

      def lc_option!(name, value, allowed)
        normalized = value.to_sym if value.is_a?(String) || value.is_a?(Symbol)
        return normalized if allowed.include?(normalized)

        raise ArgumentError, "Invalid #{name}: #{value.inspect}. Expected one of: #{allowed.map(&:inspect).join(', ')}"
      end
  end
end
