require "test_helper"

module Lostcoords::Ui
  class PartsTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)
    def render(erb) = fragment(@view.render(inline: erb))

    test "cards yield header, content and footer parts with slots" do
      html = render(<<~ERB)
        <%= lc_card do |card| %>
          <%= card.header title: "Members", description: "People here" do %><%= lc_button "Invite" %><% end %>
          <%= card.content do %>Body<% end %>
          <%= card.footer do %>Save<% end %>
        <% end %>
      ERB
      card = html.at_css("[data-slot=card]")
      assert_includes card["class"].split, "gap-inset"
      assert_equal "Members", card.at_css("h3[data-slot=card-title]").text
      assert_equal "People here", card.at_css("[data-slot=card-description]").text
      assert card.at_css("[data-slot=card-action] button[data-slot=button]")
      assert_equal %w[card-header card-content card-footer], card.element_children.map { it["data-slot"] }
    end

    test "alerts take a title and an actions part" do
      html = render('<%= lc_alert "Declined.", title: "Payment failed", tone: :warning do |alert| %><%= alert.actions do %>Retry<% end %><% end %>')
      alert = html.at_css("[data-slot=alert]")
      assert_equal "status", alert["role"]
      assert_equal "Payment failed", alert.at_css("[data-slot=alert-title]").text
      assert_equal "Declined.", alert.at_css("[data-slot=alert-description]").text
      assert_equal "Retry", alert.at_css("[data-slot=alert-actions]").text
      assert_raises(ArgumentError) { @view.lc_alert(nil) }
    end

    test "dialogs describe themselves and yield footer and close parts" do
      html = render('<%= lc_dialog id: "d", title: "Create", description: "Name it" do |dialog| %><%= dialog.footer do %><%= dialog.close %><% end %><% end %>')
      dialog = html.at_css("dialog")
      assert_equal "d-description", dialog["aria-describedby"]
      assert_equal "Name it", dialog.at_css("#d-description").text
      close = dialog.at_css("[data-slot=dialog-footer] [data-slot=dialog-close]")
      assert_equal "lc-dialog#close", close["data-action"]
      assert_equal "Cancel", close.text
      assert_equal "Close Create", dialog.at_css("header button")["aria-label"]
    end

    test "fields yield an object that splats into controls and accept several errors" do
      html = render('<%= lc_field label: "Name", id: "n", error: ["Too short", "Taken"] do |field| %><%= lc_input **field %><% end %>')
      input = html.at_css("input")
      assert_equal "n", input["id"]
      assert_equal "true", input["aria-invalid"]
      assert_equal "n-error", input["aria-describedby"]
      assert_equal %w[Too\ short Taken], html.at_css("[data-slot=field-error]").children.select(&:text?).map(&:text)
      assert_equal "true", html.at_css("[data-slot=field]")["data-invalid"]
    end

    test "buttons expose slot, variant and size" do
      button = fragment(@view.lc_button("Save", variant: :secondary, size: :sm)).at_css("button")
      assert_equal %w[button secondary sm], %w[data-slot data-variant data-size].map { button[it] }
    end

    test "checkboxes, radios and switches" do
      html = fragment(@view.lc_switch("Public", name: "public", checked: true, hint: "Visible"))
      assert_equal "0", html.at_css("input[type=hidden][name=public]")["value"]
      switch = html.at_css("input[role=switch]")
      assert switch["checked"]
      assert_includes switch["class"].split, "lc-switch"
      assert_includes html.at_css("label").text, "Visible"

      checkbox = fragment(@view.lc_checkbox("Email me", name: "notify", unchecked_value: nil))
      assert_nil checkbox.at_css("input[type=hidden]")
      assert_equal "Email me", checkbox.at_css("label").text

      radio = fragment(@view.lc_choice_group(legend: "Plan", error: "Pick one") { @view.lc_radio("Free", name: "plan", value: "free") })
      assert_equal "Plan", radio.at_css("fieldset legend").text
      assert_equal "true", radio.at_css("fieldset")["aria-invalid"]
      assert radio.at_css("input[type=radio][name=plan][value=free]")
    end

    test "tabs connect tabs and panels and select the first by default" do
      html = render('<%= lc_tabs id: "t", label: "Project" do |tabs| %><% tabs.panel "Overview" do %>A<% end %><% tabs.panel "Team members", value: :team do %>B<% end %><% end %>')
      tabs = html.css("[role=tab]")
      panels = html.css("[role=tabpanel]")
      assert_equal %w[true false], tabs.map { it["aria-selected"] }
      assert_equal %w[0 -1], tabs.map { it["tabindex"] }
      assert_equal tabs.map { it["aria-controls"] }, panels.map { it["id"] }
      assert_equal [ nil, "hidden" ], panels.map { it["hidden"] }
      assert_equal "Project", html.at_css("[role=tablist]")["aria-label"]
      assert_equal "lc-tabs", html.at_css("[data-slot=tabs]")["data-controller"]

      selected = render('<%= lc_tabs id: "t", label: "P", selected: "b" do |tabs| %><% tabs.panel "A" do %>1<% end %><% tabs.panel "B", value: "b" do %>2<% end %><% end %>')
      assert_equal "B", selected.at_css("[aria-selected=true]").text
      assert_raises(ArgumentError) { @view.lc_tabs(id: "t", label: "P") { } }
      assert_raises(ActionView::Template::Error) { render('<%= lc_tabs id: "t", label: "P", selected: :x do |tabs| %><% tabs.panel "A" do %>1<% end %><% end %>') }
    end

    test "tooltips describe their trigger" do
      html = render('<%= lc_tooltip "Copy link", id: "tip", side: :bottom do |tip| %><%= lc_button "Copy", **tip %><% end %>')
      assert_equal "tip", html.at_css("button")["aria-describedby"]
      assert_equal "Copy link", html.at_css("#tip[role=tooltip]").text
      assert_equal "bottom", html.at_css("[data-slot=tooltip]")["data-side"]
      assert_raises(ArgumentError) { @view.lc_tooltip("x", id: "t", side: :left) }
    end

    test "breadcrumbs link ancestors and mark the current page" do
      html = fragment(@view.lc_breadcrumb([ [ "Projects", "/p" ], "Website" ]))
      assert_equal "Breadcrumb", html.at_css("nav")["aria-label"]
      assert_equal "/p", html.at_css("li:first-child a")["href"]
      assert_equal "page", html.at_css("li:last-child span")["aria-current"]
      assert_equal 1, html.css("svg").size
      assert_raises(ArgumentError) { @view.lc_breadcrumb([]) }
    end

    test "description lists pair terms and details" do
      html = render('<%= lc_description_list do |list| %><%= list.item "Owner", "Ada" %><%= list.item("Plan") { "Pro" } %><% end %>')
      assert_equal %w[Owner Plan], html.css("dt").map(&:text)
      assert_equal %w[Ada Pro], html.css("dd").map(&:text)
    end
    test "nav lists group links and mark the current page" do
      html = render('<%= lc_nav_list label: "Docs" do |nav| %><%= nav.group "Guides" do %><%= nav.link "Install", "/install", current: true %><%= nav.link "Theme", "/theme" %><% end %><% end %>')
      assert_equal "Docs", html.at_css("nav")["aria-label"]
      assert_equal "Guides", html.at_css("[data-slot=nav-group] ul")["aria-label"]
      assert_equal "page", html.at_css("a[href='/install']")["aria-current"]
      assert_nil html.at_css("a[href='/theme']")["aria-current"]
      assert_empty html.css("[id]"), "groups render no ids, so the navigation can appear twice"

      compact = render('<%= lc_nav_list label: "On this page", compact: true do |nav| %><%= nav.link "Usage", "#usage", indent: true %><% end %>')
      assert_equal "true", compact.at_css("nav")["data-compact"]
      assert_includes compact.at_css("li")["class"], "ps-content"
    end

    test "pagers link previous and next pages" do
      html = fragment(@view.lc_pager(previous: [ "Button", "/button" ], next: [ "Card", "/card" ]))
      assert_equal "prev", html.at_css("a[href='/button']")["rel"]
      assert_includes html.at_css("a[rel=next]").text, "Card"
      compact = fragment(@view.lc_pager(next: [ "Card", "/card" ], compact: true))
      assert_equal "Next: Card", compact.at_css("a")["aria-label"]
      assert_equal 1, compact.css("a").size
      assert_raises(ArgumentError) { @view.lc_pager }
    end

    test "links, skip links and radio cards" do
      link = fragment(@view.lc_link("Guide", "/guide", tone: :muted)).at_css("a")
      assert_includes link["class"].split, "text-muted-foreground"
      assert_raises(ArgumentError) { @view.lc_link("Guide", nil) }
      assert_raises(ArgumentError) { @view.lc_link("Guide", "/", tone: :loud) }

      skip = fragment(@view.lc_skip_link).at_css("a")
      assert_equal [ "#main", "Skip to content" ], [ skip["href"], skip.text ]
      assert_includes skip["class"].split, "sr-only"

      card = fragment(@view.lc_radio("Team", name: "plan", value: "team", card: true) { "Preview" })
      label = card.at_css("label")
      assert_equal "true", label["data-card"]
      assert_includes label["class"].split, "has-checked:border-primary"
      assert_includes label.text, "Preview"
    end

    test "tooltips can be dismissed with Escape" do
      html = render('<%= lc_tooltip "Copy", id: "tip" do |tip| %><%= lc_button "Copy", **tip %><% end %>')
      tooltip = html.at_css("[data-slot=tooltip]")
      assert_equal "lc-tooltip", tooltip["data-controller"]
      assert_includes tooltip["data-action"], "keydown@window->lc-tooltip#dismiss"
    end
  end
end
