require "test_helper"

module Lostcoords::Ui
  class LayoutPiecesTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)
    def render(erb) = fragment(@view.render(inline: erb))

    test "collapsibles keep the titled card by default" do
      details = render('<%= lc_collapsible title: "Details" do %>Body<% end %>').at_css("details")
      assert_includes details["class"].split, "lc-card"
      assert_equal "Details", details.at_css("summary").text
      assert_nil details.at_css("[data-slot=collapsible-indicator]")
    end

    test "collapsibles take a custom summary without a card" do
      html = render(<<~ERB)
        <%= lc_collapsible card: false, indicator: :chevron, summary_class: "px-3 hover:bg-muted", data: { form_target: "split" } do |collapsible| %>
          <% collapsible.summary data: { form_target: "summary" } do %><span>Language</span><span>English</span><% end %>
          <p>Options</p>
        <% end %>
      ERB
      details = html.at_css("details")
      summary = details.at_css("> summary")
      assert_not_includes details["class"].split, "lc-card"
      assert_includes details["class"].split, "lc-collapsible"
      assert_equal "lc-collapsible", details["data-controller"]
      assert_equal "split", details["data-form-target"]
      assert_equal "summary", summary["data-form-target"]
      assert_equal %w[Language English], summary.css("span").map(&:text)
      assert summary.at_css("svg[data-slot=collapsible-indicator][aria-hidden=true]")
      assert_includes summary["class"].split, "px-3"
      assert_includes summary["class"].split, "list-none"
      assert_equal "Options", details.at_css("[data-slot=collapsible-content] p").text
    end

    test "collapsibles need a title or a summary and a known indicator" do
      assert_raises(ArgumentError) { @view.lc_collapsible { "Body" } }
      assert_raises(ArgumentError) { @view.lc_collapsible(title: "Details", indicator: :arrow) }
      summary = fragment(@view.lc_collapsible(title: "Invite", indicator: :none, summary_class: @view.lc_button_class(variant: :secondary, size: :sm))).at_css("summary")
      assert_includes summary["class"].split, "inline-flex"
      assert_not_includes summary["class"].split, "flex"
    end

    test "toast regions place themselves per breakpoint" do
      region = fragment(@view.lc_toast_region).at_css("[data-slot=toast-region]")
      assert_equal "bottom-end", region["data-placement"]
      assert_nil region["data-mobile-placement"]

      region = fragment(@view.lc_toast_region(placement: :bottom_center, mobile_placement: "top_center")).at_css("[data-slot=toast-region]")
      assert_equal "bottom-center", region["data-placement"]
      assert_equal "top-center", region["data-mobile-placement"]
      assert_raises(ArgumentError) { @view.lc_toast_region(placement: :middle) }
      assert_raises(ArgumentError) { @view.lc_toast_region(mobile_placement: :left) }
    end

    test "nav lists in a row carry one indicator and mark the current link" do
      html = render(<<~ERB)
        <%= lc_nav_list label: "Project", layout: :responsive, indicator: true, data: { turbo_permanent: true } do |nav| %>
          <%= nav.link "Overview", "/overview", icon: "document-text", current: true, data: { turbo_action: "advance" } %>
          <%= nav.link "/activity", class: "sm:hidden" do %>Activity<% end %>
        <% end %>
      ERB
      nav = html.at_css("nav[data-slot=nav-list]")
      assert_equal "Project", nav["aria-label"]
      assert_equal "lc-nav", nav["data-controller"]
      assert_equal "responsive", nav["data-layout"]
      assert_equal "true", nav["data-turbo-permanent"]
      assert_equal 1, nav.css("> [data-lc-nav-target=indicator][aria-hidden=true]").size
      assert nav.css("li").all? { it["class"].split.include?("contents") }, "items take no box, so hiding a link removes its cell"
      links = nav.css("a[data-slot=nav-link]")
      assert_equal %w[/overview /activity], links.map { it["href"] }
      assert_equal [ "page", nil ], links.map { it["aria-current"] }
      assert_equal %w[link link], links.map { it["data-lc-nav-target"] }
      assert_equal "lc-nav#select", links.first["data-action"]
      assert_equal "advance", links.first["data-turbo-action"]
      assert links.first.at_css("svg[aria-hidden=true]")
      assert_equal "Overview", links.first.at_css("span").text
      assert_equal "Activity", links.last.text
      assert_includes links.last["class"].split, "sm:hidden"
    end

    test "a column nav list without an indicator keeps its 0.7 structure" do
      nav = render('<%= lc_nav_list label: "Docs" do |nav| %><%= nav.link "Install", "/install" %><% end %>').at_css("nav")
      assert_nil nav["data-controller"]
      assert_nil nav["data-layout"]
      assert_nil nav.at_css("[data-slot=nav-indicator]")
      assert_nil nav.at_css("li")["class"]
      assert_nil nav.at_css("a")["data-action"]
      assert_equal "Install", nav.at_css("a").text
    end

    test "nav lists reject unknown layouts, compact rows and links without a URL" do
      assert_raises(ArgumentError) { @view.lc_nav_list(label: "Project", layout: :sidebar) }
      assert_raises(ArgumentError) { @view.lc_nav_list(label: "Project", layout: :row, compact: true) }
      assert_raises(ArgumentError) { @view.lc_nav_link_class(compact: true, layout: :dock) }
      assert_raises(ArgumentError) { Parts::NavList.new(@view, false, :row, true).link("Overview", nil) }
    end

    test "list sections hold a heading, the rows and a footnote" do
      html = render(<<~ERB)
        <%= lc_list_section "Security", id: "security", footnote: "Sign-in methods", level: 3, class: "scroll-mt-22" do %>
          <%= lc_list_group do %>
            <%= lc_list_row "Passkey", subtitle: "Not set up", icon: "key" do %><button>Add</button><% end %>
            <%= lc_list_row "Apple", icon: tag.svg(data: { test: "logo" }), tag: :label %>
            <%= lc_list_row class: "grid" do %>Free<% end %>
            <%= lc_list_row "Docs", href: "/docs" %>
          <% end %>
        <% end %>
      ERB
      section = html.at_css("section#security[data-slot=list-section]")
      assert_equal "security-heading", section["aria-labelledby"]
      assert_includes section["class"].split, "scroll-mt-22"
      assert_equal "Security", section.at_css("h3#security-heading").text
      assert_equal "Sign-in methods", section.at_css("[data-slot=list-footnote]").text
      rows = section.css("[data-slot=list-group] > [data-slot=list-row]")
      assert_equal %w[div label div a], rows.map(&:name)
      assert rows.all? { it["class"].split.include?("lc-list-row") }
      passkey = rows.first
      assert_equal "Passkey", passkey.at_css("[data-slot=list-title]").text
      assert_equal "Not set up", passkey.at_css("[data-slot=list-subtitle]").text
      assert_equal "true", passkey.at_css("[data-slot=list-icon]")["aria-hidden"]
      assert_equal "Add", passkey.element_children.last.text, "the block trails the text"
      assert rows[1].at_css("[data-slot=list-icon] svg[data-test=logo]")
      assert_nil rows[1].at_css("[data-slot=list-subtitle]")
      assert_includes rows[2]["class"].split, "grid"
      assert_nil rows[2].at_css("[data-slot=list-text]"), "without a title the block is the whole row"
      assert_equal "/docs", rows[3]["href"]
    end

    test "a linked li or div row links its title over the row and keeps its own controls above it" do
      row = render('<%= lc_list_row "primary", subtitle: "app.localhost", href: "/logs", tag: :li do %><button>Stop</button><% end %>').at_css("li[data-slot=list-row]")
      assert_nil row["href"]
      link = row.at_css("[data-slot=list-title] > a[data-slot=list-link]")
      assert_equal "/logs", link["href"]
      assert_equal "primary", link.text
      classes = row["class"].split
      assert_includes classes, "relative"
      assert_includes classes, "hover:bg-accent"
      assert link["class"].split.include?("after:inset-0"), "the link covers the row"
      assert classes.any? { it.end_with?("]:z-raised") && it.include?(":not([data-slot=list-link])") }, "controls sit above the link"
      assert_equal "Stop", row.at_css("button").text
      div = render('<%= lc_list_row "Docs", href: "/docs", tag: :div %>').at_css("div[data-slot=list-row]")
      assert div.at_css("a[data-slot=list-link][href='/docs']")
    end

    test "list items lay out a row inside your own element" do
      item = render('<%= lc_list_item "Other devices", subtitle: "2 devices", icon: "device-phone-mobile", tag: :summary do %><span>v</span><% end %>').at_css("summary[data-slot=list-item]")
      assert_equal %w[list-icon list-text], item.element_children.first(2).map { it["data-slot"] }
      unpadded = render('<%= lc_list_row padded: false do %><%= lc_list_item "Delete", tag: :button %><% end %>').at_css("[data-slot=list-row]")
      assert_not_includes unpadded["class"].split, "px-content"
      assert unpadded.at_css("button[data-slot=list-item]")
    end

    test "list rows reject unknown tags and links on other tags" do
      assert_raises(ArgumentError) { @view.lc_list_row("Row", tag: :span) }
      assert_raises(ArgumentError) { @view.lc_list_row("Row", href: "/x", tag: :label) }
      assert_raises(ArgumentError) { @view.lc_list_row(href: "/x", tag: :li) { "Row" } }
      assert_raises(ArgumentError) { @view.lc_list_group(tag: :ol) }
      assert_raises(ArgumentError) { @view.lc_list_section("Heading", level: 7) }
      assert_raises(ArgumentError) { @view.lc_list_section("") }
    end

    test "list fields label one control, or name a group of controls with a legend" do
      field = render('<%= lc_list_field "Note", icon: "pencil", id: "note" do %><%= lc_input plain: true, id: "note", name: "note" %><% end %>').at_css("[data-slot=list-field]")
      assert_includes field["class"].split, "lc-list-row"
      label = field.at_css("label[for=note]")
      assert label.at_css("svg[aria-hidden=true]")
      assert_equal "Note", label.at_css("[data-slot=list-field-text]").text
      input = field.at_css("input#note")
      assert_equal "true", input["data-plain"]
      refute_includes input["class"].split, "h-control-md"

      group = render('<%= lc_list_field "Paid by", icon: "user", tag: :fieldset do %><div>chips</div><% end %>').at_css("fieldset")
      assert_equal "Paid by", group.at_css("legend.sr-only").text
      assert_equal "true", group.at_css("[data-slot=list-field-label]")["aria-hidden"]

      inline = render('<%= lc_list_field "Split", tag: :span, surface: false do %>Equal<% end %>').at_css("span[data-slot=list-field]")
      refute_includes inline["class"].split, "lc-list-row"
      assert_nil @view.lc_input(name: "q")[/data-plain/]
      assert_raises(ArgumentError) { @view.lc_list_field("Paid by", id: "x", tag: :fieldset) }
      assert_raises(ArgumentError) { @view.lc_list_field("Row", tag: :li) }
    end
  end
end
