require "test_helper"

module Lostcoords::Ui
  class TabBarTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)
    def render(erb) = fragment(@view.render(inline: erb))

    test "tabs are links in a labelled nav, the current one marked and underlined" do
      html = render(<<~ERB)
        <%= lc_tab_bar label: "Compose", class: "mt-4" do |bar| %>
          <%= bar.link "Open", "/drafts", current: true, count: 3 %>
          <%= bar.link "Posted", "/drafts?status=posted", count: 0, data: { turbo_frame: "drafts" } %>
          <%= bar.link "Ideas", "/ideas" %>
        <% end %>
      ERB
      nav = html.at_css("nav[data-slot=tab-bar]")
      assert_equal "Compose", nav["aria-label"]
      assert_includes nav["class"].split, "mt-4"
      assert_nil nav["data-fill"]

      links = nav.css("ul > li[data-slot=tab-bar-item] > a[data-slot=tab-bar-link]")
      assert_equal %w[/drafts /drafts?status=posted /ideas], links.map { |link| link["href"] }
      assert_equal [ "page", nil, nil ], links.map { |link| link["aria-current"] }
      assert_equal "drafts", links[1]["data-turbo-frame"]
      assert_equal [ "3", "0", nil ], links.map { |link| link.at_css("[data-slot=tab-bar-count]")&.text }
      assert_equal 1, nav.css("[data-slot=tab-bar-indicator]").size
      assert_equal "true", links[0].at_css("[data-slot=tab-bar-indicator]")["aria-hidden"]
      assert_includes links[0].at_css("[data-slot=tab-bar-indicator]")["class"], "bg-(--lc-tab-bar-indicator,var(--primary))"
      assert_includes nav.at_css("ul")["class"].split, "overflow-x-auto"
      assert_includes nav.at_css("ul")["class"].split, "lc-scroll-fade-x"
    end

    test "fill stretches the tabs to share the row" do
      nav = render('<%= lc_tab_bar label: "Inbox", fill: true do |bar| %><%= bar.link "All", "/" %><% end %>').at_css("nav")
      assert_equal "true", nav["data-fill"]
      assert_includes nav.at_css("li")["class"].split, "flex-1"
    end

    test "a tab bar needs a label, a block and linked tabs" do
      assert_raises(ArgumentError) { @view.lc_tab_bar(label: "") { "" } }
      assert_raises(ArgumentError) { @view.lc_tab_bar(label: "Tabs") }
      assert_raises(ArgumentError) { @view.lc_tab_bar(label: "Tabs") { |bar| bar.link("All", nil) } }
      assert_raises(ArgumentError) { @view.lc_tab_bar(label: "Tabs") { |bar| bar.link("", "/") } }
    end
  end
end
