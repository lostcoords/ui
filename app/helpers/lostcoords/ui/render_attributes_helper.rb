module Lostcoords::Ui
  module RenderAttributesHelper
    private
      def lc_attributes(defaults, attributes)
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
        normalized
      end

      def lc_option!(name, value, allowed)
        normalized = value.to_sym if value.is_a?(String) || value.is_a?(Symbol)
        return normalized if allowed.include?(normalized)

        raise ArgumentError, "Invalid #{name}: #{value.inspect}. Expected one of: #{allowed.map(&:inspect).join(', ')}"
      end
  end
end
