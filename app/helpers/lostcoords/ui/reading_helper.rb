require "nokogiri"

module Lostcoords::Ui
  module ReadingHelper
    PROSE_BASE =
      "prose lc-prose min-w-0 max-w-(--lc-reading-measure,65ch) " \
      "text-(length:--lc-reading-size,1rem) leading-(--lc-reading-leading,1.75)"

    def lc_prose_class(extra: nil)
      lc_tw(PROSE_BASE, extra)
    end

    # anchors: true links every h2, h3 and h4 that has an id to itself, as rendered Markdown's headings
    # do. Pass the same HTML to lc_toc(headings:) for an "On this page" list.
    def lc_prose(anchors: false, **attributes, &block)
      content = capture(&block) if block
      content = lc_anchor_headings(content) if anchors && content
      tag.div(content, **lc_attributes({ class: lc_prose_class }, attributes))
    end

    private
      def lc_anchor_headings(html)
        fragment = Nokogiri::HTML5.fragment(html.to_s)
        fragment.css("h2[id], h3[id], h4[id]").each do |heading|
          next if heading.at_css("a.lc-anchor")

          heading["class"] = [ heading["class"], "lc-anchor-target" ].compact.join(" ")
          link = Nokogiri::XML::Node.new("a", fragment.document)
          link["href"] = "##{heading['id']}"
          link["class"] = "lc-anchor"
          link["data-slot"] = "heading-anchor"
          link.children = heading.children
          heading.add_child(link)
        end
        fragment.to_html.html_safe
      end
  end
end
