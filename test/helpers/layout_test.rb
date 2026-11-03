require "test_helper"

module Lostcoords::Ui
  class LayoutTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "layout wrappers capture content and preserve native attributes" do
      [ :lc_stack, :lc_inline, :lc_container ].each do |helper|
        html = @view.public_send(helper, id: "content", data: { controller: "example" }, aria: { describedby: "hint" }) { @view.tag.p("A & B") }
        element = fragment(html).at_css("div#content")
        assert_equal "A & B", element.at_css("p").text
        assert_equal "example", element["data-controller"]
        assert_equal "hint", element["aria-describedby"]
      end
    end

    test "named spacing accepts strings and caller utilities override defaults" do
      stack = fragment(@view.lc_stack(gap: "section", class: "gap-4") { "Content" }).at_css("div")
      assert_includes stack["class"].split, "gap-4"
      assert_not_includes stack["class"], "--lc-space-section"

      inline = fragment(@view.lc_inline(gap: "tight", class: "items-start") { "Content" }).at_css("div")
      assert_includes inline["class"].split, "items-start"
      assert_not_includes inline["class"].split, "items-center"
    end

    test "reading and form containers do not add another page gutter" do
      [ :reading, :form ].each do |size|
        container = fragment(@view.lc_container(size: size) { "Content" }).at_css("div")
        assert_not_includes container["class"].split, "lc-container-page"
      end

      container = fragment(@view.lc_container(class: "max-w-4xl") { "Content" }).at_css("div")
      assert_includes container["class"].split, "lc-container-page"
      assert_includes container["class"].split, "max-w-4xl"
      assert_not_includes container["class"], "--lc-page-max"
    end

    test "sections keep heading semantics independent of visual style and capture actions" do
      html = @view.lc_section(title: "<Expenses>", level: 3, id: "expenses", actions: -> { @view.tag.a("Add", href: "/expenses/new") }) do
        @view.safe_join([ @view.tag.p("First card"), @view.tag.p("Second card") ])
      end
      section = fragment(html).at_css("section#expenses")
      assert_equal "<Expenses>", section.at_css("header > h3").text
      assert_nil section.at_css("expenses")
      assert_equal "Add", section.at_css('header > a[href="/expenses/new"]').text
      assert_equal [ "First card", "Second card" ], section.element_children.last.css("p").map(&:text)
      assert_nil section["level"]
    end

    test "section action strings are escaped while captured markup is preserved" do
      escaped = fragment(@view.lc_section(title: "Expenses", actions: "<script>bad()</script>") { "Body" })
      assert_nil escaped.at_css("script")
      assert_includes escaped.at_css("header").text, "<script>bad()</script>"

      action = @view.tag.button("Add", type: "button")
      captured = fragment(@view.lc_section(title: "Expenses", actions: action) { "Body" })
      assert_equal "Add", captured.at_css('header button[type="button"]').text
    end

    test "unknown spacing sizes blank titles and invalid heading levels are rejected" do
      assert_raises(ArgumentError) { @view.lc_stack(gap: :missing) }
      assert_raises(ArgumentError) { @view.lc_inline(gap: nil) }
      assert_raises(ArgumentError) { @view.lc_container(size: :missing) }
      assert_raises(ArgumentError) { @view.lc_section(title: " ") }
      assert_raises(ArgumentError) { @view.lc_section(title: "Expenses", level: 7) }
    end

    private
      def fragment(html)
        Nokogiri::HTML.fragment(html)
      end
  end
end
