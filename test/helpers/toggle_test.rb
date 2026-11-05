require "test_helper"

module Lostcoords::Ui
  class ToggleTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    test "a toggle link marks itself current instead of pressed" do
      link = fragment(@view.lc_toggle("May", href: "/stats?month=5", active: true, data: { turbo_frame: "stats" })).at_css("a")
      assert_equal "/stats?month=5", link["href"]
      assert_equal "true", link["aria-current"]
      assert_equal "stats", link["data-turbo-frame"]
      assert_nil link["aria-pressed"]
      assert_nil link["data-controller"]

      assert_nil fragment(@view.lc_toggle("June", href: "/stats")).at_css("a")["aria-current"]
      assert_raises(ArgumentError) { @view.lc_toggle("Off", href: "/", disabled: true) }
    end

    test "a toggle with a name wraps a visually hidden radio" do
      label = fragment(@view.lc_toggle(name: :source, value: "friend", active: true, input: { class: "peer" }) { "A friend" }).at_css("label")
      radio = label.at_css("input[type=radio]")
      assert_equal %w[source friend], [ radio["name"], radio["value"] ]
      assert radio.key?("checked")
      assert_equal %w[sr-only peer], radio["class"].split
      assert_equal "A friend", label.text
      assert_equal "toggle", label["data-slot"]
      refute fragment(@view.lc_toggle("Search", name: :source)).at_css("input").key?("checked")
    end

    test "a toggle whose caller sets aria-pressed or aria-expanded leaves the state to the caller" do
      button = fragment(@view.lc_toggle("Food", aria: { pressed: "true" }, data: { value: "food" })).at_css("button")
      assert_equal "true", button["aria-pressed"]
      assert_nil button["data-controller"]
      assert_nil button["data-action"]
      assert_equal "button", button["type"]

      disclosure = fragment(@view.lc_toggle("JPY", "aria-expanded": "false", data: { action: "picker#open" })).at_css("button")
      assert_nil disclosure["aria-pressed"]
      assert_equal "false", disclosure["aria-expanded"]
      assert_equal "picker#open", disclosure["data-action"]
      assert_raises(ArgumentError) { @view.lc_toggle("Food", active: true, aria: { pressed: true }) }
    end

    test "a nav toggle group renders links and marks the current one" do
      nav = fragment(@view.lc_toggle_group(label: "Period", as: :nav) do
        @view.safe_join([ @view.lc_toggle_group_item("Month", href: "/m", current: true), @view.lc_toggle_group_item("Year", href: "/y") ])
      end).at_css("nav")
      assert_equal "Period", nav["aria-label"]
      assert_nil nav["role"]
      assert_nil nav["data-controller"]
      assert_equal [ "true", nil ], nav.css("a").map { it["aria-current"] }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Period", as: :nav, name: "period") { "" } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Period", as: :nav) { @view.lc_toggle_group_item("Month", value: "m") } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Period", as: :section) { "" } }
    end

    test "a named toggle group wraps native radios and checks the group's value" do
      group = fragment(@view.lc_toggle_group(label: "Mode", name: :mode, value: "up", class: "w-full") do
        @view.safe_join([ @view.lc_toggle_group_item("Sign in", value: "in"), @view.lc_toggle_group_item("Sign up", value: "up", input: { class: "peer" }), @view.lc_toggle_group_item("SSO", value: "sso", disabled: true) ])
      end).at_css("div")
      assert_equal "radiogroup", group["role"]
      assert_nil group["data-controller"]
      assert_includes group["class"].split, "w-full"
      radios = group.css("label > input[type=radio]")
      assert_equal %w[mode mode mode], radios.map { it["name"] }
      assert_equal [ false, true, false ], radios.map { it.key?("checked") }
      assert_equal %w[sr-only peer], radios[1]["class"].split
      assert radios[2].key?("disabled")
      assert_nil group.css("label")[2]["disabled"]
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Mode", name: :mode) { @view.lc_toggle_group_item("In", value: "in", selected: true) } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Mode", name: :mode) { @view.lc_toggle_group_item("In", href: "/in") } }
    end

    test "items outside a group, and after a nested group, render as buttons" do
      assert fragment(@view.lc_toggle_group_item("Solo", value: "solo")).at_css("button[role=radio]")
      html = @view.lc_toggle_group(label: "Outer") do
        @view.safe_join([ @view.lc_toggle_group(label: "Inner", as: :nav) { @view.lc_toggle_group_item("A", href: "/a") }, @view.lc_toggle_group_item("B", value: "b") ])
      end
      assert fragment(html).at_css("button[role=radio][data-value=b]")
      assert_raises(ArgumentError) { @view.lc_toggle_group_item("Link", href: "/") }
    end

    test "tabs pass list attributes to the tab list" do
      html = fragment(@view.lc_tabs(id: "t", label: "Graph", list: { class: "justify-self-start", data: { turbo_permanent: true } }) { |tabs| tabs.panel("A") { "1" } })
      list = html.at_css("[role=tablist]")
      assert_includes list["class"].split, "justify-self-start"
      assert_equal "tabs-list", list["data-slot"]
      assert_equal "true", list["data-turbo-permanent"]
      assert_equal "Graph", list["aria-label"]
    end

    private
      def fragment(html)
        Nokogiri::HTML5.fragment(html)
      end
  end
end
