module Lostcoords::Ui
  module IconHelper
    def lc_icon(name, variant: :outline, options: {}, path_options: {})
      svg = Icons.fetch(name, variant)
      path_options.each do |key, value|
        attribute = key.to_s.dasherize
        svg.css("path").each { |path| path[attribute] = value.to_s if path.key?(attribute) }
      end
      defaults = svg.attribute_nodes.to_h { |attribute| [ attribute.name.to_sym, attribute.value ] }
      defaults.merge!(xmlns: "http://www.w3.org/2000/svg", class: "lc-icon")
      options = options.transform_keys { |key| key.to_s.dasherize.to_sym }
      tag.svg(svg.children.to_xml.html_safe, **lc_attributes(defaults, options))
    end
  end
end
