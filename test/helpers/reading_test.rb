require "test_helper"

module Lostcoords::Ui
  class ReadingTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "reading wrappers capture escaped markup and preserve native attributes" do
      html = @view.ui_prose(id: "guide", lang: "ja", class: [ "mx-auto", { "w-full" => true } ], aria: { labelledby: "title" }) do
        @view.tag.p("<script> & text")
      end
      prose = Nokogiri::HTML.fragment(html).at_css("#guide")

      assert_equal "ja", prose["lang"]
      assert_equal "title", prose["aria-labelledby"]
      assert_includes prose["class"].split, "prose"
      assert_includes prose["class"].split, "ui-prose"
      assert_includes prose["class"].split, "mx-auto"
      assert_includes prose["class"].split, "w-full"
      assert_equal "<script> & text", prose.at_css("p").text
      assert_nil prose.at_css("script")
    end

    test "reading wrappers retain the plugin escape hatch for interactive content" do
      html = @view.ui_prose do
        @view.tag.div(class: "not-prose") { @view.ui_button("Continue") }
      end

      assert_equal "Continue", Nokogiri::HTML.fragment(html).at_css(".ui-prose .not-prose button").text
    end

    test "reading size measure and leading allow ordinary utility overrides" do
      prose = Nokogiri::HTML.fragment(@view.ui_prose(class: "max-w-none text-lg leading-relaxed") { "Text" }).at_css("div")

      assert_includes prose["class"].split, "max-w-none"
      assert_includes prose["class"].split, "text-lg"
      assert_includes prose["class"].split, "leading-relaxed"
      assert_not_includes prose["class"], "--ui-reading-measure"
      assert_not_includes prose["class"], "--ui-reading-size"
      assert_not_includes prose["class"], "--ui-reading-leading"
    end

    test "field spacing belongs inside fields and caller layout controls sibling spacing" do
      html = @view.tag.div(class: "grid gap-5") do
        @view.safe_join([ "first", "second" ].map do |id|
          @view.ui_field(label: id.capitalize, id: id, hint: "Help") do |control|
            @view.ui_input(**control)
          end
        end)
      end
      fields = Nokogiri::HTML.fragment(html).at_css("div").element_children

      assert_equal 2, fields.length
      fields.each do |field|
        assert_equal [ "label", "input", "p" ], field.element_children.map(&:name)
        assert_includes field["class"].split, "grid"
        assert_includes field["class"].split, "gap-2"
        assert_empty field["class"].split.grep(/(?:^|:)m[bt]-/)
        assert_empty field.at_css("label")["class"].split.grep(/(?:^|:)m[bt]-/)
      end
    end
  end
end
