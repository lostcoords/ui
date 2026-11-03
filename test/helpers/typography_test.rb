require "test_helper"

module Lostcoords::Ui
  class TypographyTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "heading level controls semantics independently of visual size" do
      heading = fragment(@view.lc_heading("Expenses", level: 3, size: :title)).at_css("h3")

      assert_equal "Expenses", heading.text
      assert_includes heading["class"].split, "text-title"
      assert_nil fragment(@view.lc_heading("Expenses", level: 3)).at_css("h2")
      assert fragment(@view.lc_heading("Expenses")).at_css("h2.text-heading")
    end

    test "heading content is escaped and native attributes are preserved" do
      heading = fragment(@view.lc_heading("<Expenses>", level: 1, id: "title", lang: "ja", data: { controller: "title" }, aria: { describedby: "subtitle" }, class: [ "text-primary", { "min-w-0" => true } ])).at_css("h1")

      assert_equal "<Expenses>", heading.text
      assert_nil heading.at_css("expenses")
      assert_equal "title", heading["id"]
      assert_equal "ja", heading["lang"]
      assert_equal "title", heading["data-controller"]
      assert_equal "subtitle", heading["aria-describedby"]
      assert_includes heading["class"].split, "text-primary"
      assert_not_includes heading["class"].split, "text-foreground"
      assert_includes heading["class"].split, "min-w-0"
    end

    test "text uses paragraphs with named sizes and tones" do
      paragraph = fragment(@view.lc_text("<Details>", size: "small", tone: "muted")).at_css("p")

      assert_equal "<Details>", paragraph.text
      assert_nil paragraph.at_css("details")
      assert_includes paragraph["class"].split, "text-small"
      assert_includes paragraph["class"].split, "text-muted-foreground"
      assert fragment(@view.lc_text("Details")).at_css("p.text-body")
      assert fragment(@view.lc_text("Updated today", size: :caption, tone: :muted)).at_css("p.text-caption.text-muted-foreground")
    end

    test "typography blocks capture markup and preserve attributes" do
      heading = @view.lc_heading(level: 4, size: :subheading) { @view.tag.em("Shared expenses") }
      paragraph = @view.lc_text(id: "description", lang: "ja", data: { state: "ready" }) { @view.tag.strong("Details") }

      assert_equal "Shared expenses", fragment(heading).at_css("h4.text-subheading em").text
      assert_equal "Details", fragment(paragraph).at_css("p#description strong").text
      assert_equal "ja", fragment(paragraph).at_css("p")["lang"]
      assert_equal "ready", fragment(paragraph).at_css("p")["data-state"]
    end

    test "typography rejects invalid roles and unsafe heading levels" do
      [ 0, 7, "2", 2.0, nil, :h2, "script" ].each do |level|
        assert_raises(ArgumentError) { @view.lc_heading("Title", level: level) }
      end
      assert_raises(ArgumentError) { @view.lc_heading("Title", size: :huge) }
      assert_raises(ArgumentError) { @view.lc_text("Details", size: nil) }
      assert_raises(ArgumentError) { @view.lc_text("Details", tone: :destructive) }
      assert_raises(ArgumentError) { @view.lc_heading_class(size: :huge) }
      assert_raises(ArgumentError) { @view.lc_text_class(tone: :destructive) }
    end

    private
      def fragment(html)
        Nokogiri::HTML.fragment(html)
      end
  end
end
