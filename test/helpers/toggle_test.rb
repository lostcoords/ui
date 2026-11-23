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

    test "toggle group items take an icon, alone or above their label" do
      nav = fragment(@view.lc_toggle_group(label: "View", as: :nav) do
        @view.safe_join([ @view.lc_toggle_group_item("List", href: "/", current: true, icon: "list-bullet", icon_only: true), @view.lc_toggle_group_item("Calendar", href: "/c", icon: "calendar-days") ])
      end)
      list, calendar = nav.css("a")
      assert_equal "List", list.at_css(".sr-only").text
      assert_equal "true", list["data-icon-only"]
      assert_includes list["class"].split, "aspect-square"
      assert_equal "Calendar", calendar.text.strip
      assert_equal "true", calendar.at_css("svg")["aria-hidden"]
      assert_raises(ArgumentError) { @view.lc_toggle_group_item(value: "x", icon: "list-bullet", icon_only: true) { "X" } }

      stacked = fragment(@view.lc_toggle_group(label: "Access", name: "access", value: "open", layout: :stacked) { @view.lc_toggle_group_item("Open", value: "open", icon: "globe-alt") })
      assert_includes stacked.at_css("label")["class"].split, "flex-col"
      adaptive = fragment(@view.lc_toggle_group(label: "Split", layout: :adaptive) { @view.lc_toggle_group_item("Equal", value: "equal") })
      assert_includes adaptive.at_css("[role=radiogroup]")["class"].split, "w-full"
      assert_includes adaptive.at_css("button")["class"].split, "@max-sm/lc-toggle:flex-col"
      assert_not_includes adaptive.at_css("button")["class"].split, "flex-col"
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Split", layout: :grid) { "" } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Split", variant: :pills, layout: :stacked) { "" } }
    end

    test "a scrolling toggle group keeps its items whole and fades its edges" do
      group = fragment(@view.lc_toggle_group(label: "Range", as: :nav, scroll: true) { @view.lc_toggle_group_item("All", href: "/") }).at_css("nav")
      assert_includes group["class"].split, "overflow-x-auto"
      assert_includes group["class"].split, "lc-scroll-fade-x"
      assert_includes group["class"].split, "*:shrink-0"
    end

    test "pills scroll in one row, always or only inside a narrow container" do
      always = fragment(@view.lc_toggle_group(label: "Category", name: "category", variant: :pills, scroll: true) { @view.lc_toggle_group_item("Food", value: "food") }).at_css("[role=radiogroup]")["class"].split
      assert_includes always, "flex-nowrap"
      assert_includes always, "overflow-x-auto"
      assert_includes always, "lc-scroll-fade-x"
      assert_not_includes always, "flex-wrap"

      narrow = fragment(@view.lc_toggle_group(label: "Category", name: "category", variant: :pills, scroll: :narrow) { @view.lc_toggle_group_item("Food", value: "food") }).at_css("[role=radiogroup]")["class"].split
      assert_includes narrow, "flex-wrap"
      assert_includes narrow, "@max-md:flex-nowrap"
      assert_includes narrow, "@max-md:overflow-x-auto"
      assert_includes narrow, "lc-scroll-fade-x"

      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Range", scroll: :narrow) { "" } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Category", variant: :pills, scroll: :wide) { "" } }
    end

    test "a pills toggle group wraps toggle pills and accepts an empty value" do
      html = fragment(@view.lc_toggle_group(label: "Category", name: "category", value: "", variant: :pills) do
        @view.safe_join([ @view.lc_toggle_group_item("Leave unchanged", value: ""), @view.lc_toggle_group_item("Food", value: "food") ])
      end)
      group = html.at_css("[role=radiogroup]")
      assert_includes group["class"].split, "flex-wrap"
      assert_not_includes group["class"].split, "bg-track"
      assert html.css("label").all? { it["class"].split.include?("rounded-pill") }
      assert_equal [ "", "food" ], html.css("input").map { it["value"] }
      assert html.at_css("input[value='']").key?("checked")

      buttons = fragment(@view.lc_toggle_group(label: "Size", variant: :pills) { @view.lc_toggle_group_item("S", value: "s", selected: true) })
      assert_equal "true", buttons.at_css("button[role=radio]")["aria-checked"]
      assert_includes buttons.at_css("button")["class"].split, "rounded-pill"
      small = fragment(@view.lc_toggle_group(label: "Size", variant: :pills, size: :sm) { @view.lc_toggle_group_item("S", value: "s") })
      assert_equal @view.lc_toggle_class(size: :sm), small.at_css("button")["class"]
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Size", size: :sm) { "" } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Size", variant: :cards) { "" } }
      assert_raises(ArgumentError) { @view.lc_toggle_group(label: "Size") { @view.lc_toggle_group_item { "S" } } }
    end

    test "a collapsible with button: styles its summary as that button" do
      summary = fragment(@view.lc_collapsible(title: "Invite", card: false, button: { variant: :secondary, size: :sm }, summary_class: "w-fit") { "Form" }).at_css("summary")
      assert_equal @view.lc_tw(@view.lc_button_class(variant: :secondary, size: :sm), "list-none [&::-webkit-details-marker]:hidden w-fit"), summary["class"]
      assert_raises(ArgumentError) { @view.lc_collapsible(title: "Invite", button: { block: true }) }
    end

    test "tabs pass list attributes to the tab list" do
      html = fragment(@view.lc_tabs(id: "t", label: "Graph", list: { class: "justify-self-start", data: { turbo_permanent: true } }) { |tabs| tabs.panel("A") { "1" } })
      list = html.at_css("[role=tablist]")
      assert_includes list["class"].split, "justify-self-start"
      assert_equal "tabs-list", list["data-slot"]
      assert_equal "true", list["data-turbo-permanent"]
      assert_equal "Graph", list["aria-label"]
    end

    test "an icon-only toggle keeps its label as the accessible name" do
      button = fragment(@view.lc_toggle("Bold", icon: "bold", icon_only: true, active: true)).at_css("button")
      assert_equal "true", button["aria-pressed"]
      assert_equal "true", button["data-icon-only"]
      assert_equal "Bold", button.at_css("span.sr-only").text
      assert_equal "true", button.at_css("svg")["aria-hidden"]
      assert_nil button.at_css("svg")["data-icon"]
      assert_includes button["class"].split, "aspect-square"
      assert_includes button["class"].split, "px-0"

      tip = fragment(@view.lc_toggle("Italic", icon: "italic", icon_only: true, tooltip: true)).at_css("[data-slot=tooltip]")
      assert_equal "Italic", tip.at_css("[data-slot=tooltip-content]").text
      assert_equal "true", tip.at_css("[data-slot=tooltip-content]")["aria-hidden"]
      assert tip.at_css("button[data-slot=toggle][aria-pressed=false]")

      described = fragment(@view.lc_toggle("Pin", icon: "bookmark", icon_only: true, tooltip: "Keep at the top", id: "pin")).at_css("[data-slot=tooltip]")
      assert_equal "pin-tooltip", described.at_css("button")["aria-describedby"]

      link = fragment(@view.lc_toggle("Grid", icon: "squares-2x2", icon_only: true, href: "/grid", active: true)).at_css("a")
      assert_equal "true", link["aria-current"]
      assert_equal "Grid", link.at_css(".sr-only").text

      radio = fragment(@view.lc_toggle("List", icon: "list-bullet", icon_only: true, name: "view", value: "list")).at_css("label")
      assert radio.at_css("input[type=radio][value=list]")
      assert_equal "List", radio.at_css("span.sr-only").text
    end

    test "icon: adds a leading icon to a labelled toggle" do
      button = fragment(@view.lc_toggle("Pinned", icon: "bookmark")).at_css("button")
      assert_equal "inline-start", button.at_css("svg")["data-icon"]
      assert_equal "Pinned", button.text
      assert_raises(ArgumentError) { @view.lc_toggle("Bold", icon_only: true) }
      assert_raises(ArgumentError) { @view.lc_toggle(icon: "bold", icon_only: true) }
    end

    private
      def fragment(html)
        Nokogiri::HTML5.fragment(html)
      end
  end
end
