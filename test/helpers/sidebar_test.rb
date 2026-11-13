require "test_helper"

module Lostcoords::Ui
  class SidebarTest < ActionView::TestCase
    def fragment(html) = Nokogiri::HTML.fragment(html)

    def sidebar(**options)
      fragment(render(inline: <<~ERB, locals: { options: options }))
        <%= lc_sidebar(**options) do |sidebar| %>
          <%= sidebar.header do %><a href="/">Acme</a><% end %>
          <%= sidebar.body do %>
            <%= lc_nav_list label: "Main" do |nav| %><%= nav.link "Home", "/", icon: "home", current: true %><% end %>
          <% end %>
          <%= sidebar.footer do %>
            <%= sidebar.account "Ada", detail: "ada@example.com", avatar: lc_avatar("AL", size: :sm), id: "account" do %>
              <%= lc_menu_option "Sign out", href: "/session", method: :delete %>
            <% end %>
          <% end %>
        <% end %>
      ERB
    end

    test "the sidebar is a labelled aside with header, body and footer slots" do
      aside = sidebar.at_css("aside[data-slot=sidebar]")
      assert_equal "Sidebar", aside["aria-label"]
      assert_equal %w[lc-sidebar lc-scroll-keeper], aside["data-controller"].split
      assert_equal "xl", aside["data-rail-below"]
      assert_equal "lc_sidebar", aside["data-lc-sidebar-cookie-value"]
      assert_equal "lc_sidebar", aside["data-lc-scroll-keeper-key-value"]
      assert_equal "Collapse sidebar", aside["data-lc-sidebar-collapse-label-value"]
      assert_equal "Expand sidebar", aside["data-lc-sidebar-expand-label-value"]
      assert_nil aside["data-collapsed"]
      assert_nil aside["data-expanded"]
      assert_equal %w[sidebar-header sidebar-body sidebar-footer], aside.element_children.map { |child| child["data-slot"] }
      assert_includes aside["class"].split, "lc-rail:w-(--lc-sidebar-rail-width,4rem)"
    end

    test "the header renders the toggle after its content" do
      header = sidebar.at_css("[data-slot=sidebar-header]")
      assert_equal "Acme", header.element_children.first.text
      toggle = header.at_css("button[data-slot=sidebar-toggle]")
      assert_equal "Collapse sidebar", toggle["aria-label"]
      assert_equal "Collapse sidebar", toggle["title"]
      assert_equal "true", toggle["aria-expanded"]
      assert_equal "lc-sidebar#toggle", toggle["data-action"]
      assert_equal "toggle", toggle["data-lc-sidebar-target"]
    end

    # test/integration/sidebar_test.rb reads the cookie through a real request.
    test "state: decides how the server renders it" do
      collapsed = sidebar(state: "collapsed").at_css("aside")
      assert_equal "true", collapsed["data-collapsed"]
      toggle = collapsed.at_css("[data-slot=sidebar-toggle]")
      assert_equal "Expand sidebar", toggle["aria-label"]
      assert_equal "false", toggle["aria-expanded"]

      expanded = sidebar(state: "expanded").at_css("aside")
      assert_equal "true", expanded["data-expanded"]
      assert_nil expanded["data-collapsed"]

      ignored = sidebar(state: "sideways").at_css("aside")
      assert_nil ignored["data-collapsed"]
      assert_nil ignored["data-expanded"]
    end

    test "rail_below picks the breakpoint, or none" do
      assert_equal "lg", sidebar(rail_below: :lg).at_css("aside")["data-rail-below"]
      assert_equal "2xl", sidebar(rail_below: "2xl").at_css("aside")["data-rail-below"]
      assert_nil sidebar(rail_below: false).at_css("aside")["data-rail-below"]
      assert_raises(ArgumentError) { view.lc_sidebar(rail_below: :sm) { "" } }
      assert_raises(ArgumentError) { view.lc_sidebar }
    end

    test "the account row opens a menu and folds to its avatar on the rail" do
      account = sidebar.at_css("[data-slot=sidebar-footer] [data-slot=sidebar-account]")
      assert_equal "lc-menu", account["data-controller"]
      trigger = account.at_css("button[data-slot=sidebar-account-trigger]")
      assert_equal "account", trigger["aria-controls"]
      assert_equal "menu", trigger["aria-haspopup"]
      assert_equal "Ada", trigger["title"]
      assert trigger.at_css("[data-slot=avatar]")
      text = trigger.at_css("[data-slot=sidebar-account-text]")
      assert_equal "Adaada@example.com", text.text
      assert_includes text["class"].split, "lc-rail:sr-only"
      assert_includes trigger.at_css("svg:last-child")["class"].split, "lc-rail:hidden"
      menu = account.at_css("#account[role=menu]")
      assert_equal "account-trigger", menu["aria-labelledby"]
      assert menu.at_css("form[action='/session']")
    end
  end
end
