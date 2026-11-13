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

    test "stacks and inline groups render as the element their content needs" do
      list = Nokogiri::HTML.fragment(@view.lc_stack(as: :ul, gap: :related) { @view.tag.li("One") }).at_css("ul.gap-related li")
      aside = Nokogiri::HTML.fragment(@view.lc_inline(as: "aside", aria: { label: "Filters" })).at_css("aside")

      assert_equal "One", list.text
      assert_equal "Filters", aside["aria-label"]
      assert_raises(ArgumentError) { @view.lc_stack(as: :span) }
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

    test "section headers hold a heading row and glass takes an element" do
      header = fragment(@view.lc_section_header(id: "head") { @view.lc_heading("Groups") }).at_css("header#head")
      assert_equal @view.lc_section_header_class.split, header["class"].split
      assert fragment(@view.lc_section_header(as: :div) { "" }).at_css("div")
      assert fragment(@view.lc_section(title: "Groups") { "" }).at_css("section > header h2")

      glass = fragment(@view.lc_glass(shape: :panel, as: :label, for: "q") { "Search" }).at_css("label[for=q][data-slot=glass]")
      assert_includes glass["class"].split, "lc-glass"
      assert_includes glass["class"].split, "rounded-3xl"
      assert_raises(ArgumentError) { @view.lc_glass(as: :button) }
    end

    test "unknown spacing sizes blank titles and invalid heading levels are rejected" do
      assert_raises(ArgumentError) { @view.lc_stack(gap: :missing) }
      assert_raises(ArgumentError) { @view.lc_inline(gap: nil) }
      assert_raises(ArgumentError) { @view.lc_container(size: :missing) }
      assert_raises(ArgumentError) { @view.lc_section(title: " ") }
      assert_raises(ArgumentError) { @view.lc_section(title: "Expenses", level: 7) }
    end

    test "a split puts a main column beside a fixed aside from lg" do
      split = fragment(@view.lc_split(as: :section, class: "mt-4") { @view.tag.main("Main") + @view.tag.aside("Aside") }).at_css("section")
      assert_equal %w[main aside], split.element_children.map(&:name)
      assert_includes split["class"].split, "lg:grid-cols-[minmax(0,1fr)_20rem]"
      assert_includes split["class"].split, "items-start"
      assert_includes split["class"].split, "mt-4"
      assert_equal "grid min-w-0 items-start gap-section lg:grid-cols-[minmax(0,1fr)_24rem]", @view.lc_split_class(aside: :lg)
      assert_raises(ArgumentError) { @view.lc_split(aside: :xl) }
    end

    test "columns flow groups into balanced columns without breaking one" do
      columns = fragment(@view.lc_columns { @view.tag.section("A") }).at_css("div")
      assert_includes columns["class"].split, "lg:columns-2"
      assert_includes columns["class"].split, "*:break-inside-avoid"
      assert_includes @view.lc_columns_class(count: 3).split, "xl:columns-3"
      assert_raises(ArgumentError) { @view.lc_columns(count: 4) }
    end

    private
      def fragment(html)
        Nokogiri::HTML.fragment(html)
      end
  end
end
