require "test_helper"

module Lostcoords::Ui
  class ShellTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)
    def render(erb) = fragment(@view.render(inline: erb))

    test "anchored headings and sections link to their target" do
      heading = fragment(@view.lc_heading("Usage <b>", id: "usage", anchor: true)).at_css("h2#usage")
      assert_includes heading["class"].split, "lc-anchor-target"
      assert_equal "#usage", heading.at_css("a.lc-anchor")["href"]
      assert_equal "Usage <b>", heading.at_css("a").text

      linked = fragment(@view.lc_heading("Sizes", level: 3, anchor: "example-1")).at_css("h3")
      assert_nil linked["id"]
      assert_not_includes linked["class"].split, "lc-anchor-target"
      assert_equal "#example-1", linked.at_css("a")["href"]

      section = fragment(@view.lc_section(title: "API", id: "api", anchor: true) { "Body" }).at_css("section#api")
      assert_includes section["class"].split, "lc-anchor-target"
      assert_equal "#api", section.at_css("header h2 a[data-slot=heading-anchor]")["href"]

      assert_nil fragment(@view.lc_section(title: "Plain", id: "plain") { "" }).at_css("a")
      assert_raises(ArgumentError) { @view.lc_heading("Usage", anchor: true) }
      assert_raises(ArgumentError) { @view.lc_section(title: "Usage", anchor: true) { "" } }
    end

    test "prose links its headings that have ids" do
      html = fragment(@view.lc_prose(anchors: true) { '<h2 id="start">Start <code>x</code></h2><h3>No id</h3><p>Text</p>'.html_safe })
      link = html.at_css("h2#start.lc-anchor-target > a.lc-anchor[href='#start']")
      assert_equal "Start x", link.text
      assert_nil html.at_css("h3 a")

      plain = fragment(@view.lc_prose { '<h2 id="start">Start</h2>'.html_safe })
      assert_nil plain.at_css("a")
    end

    test "tables of contents list links or rendered headings and spy on scroll" do
      toc = render('<%= lc_toc do |toc| %><%= toc.link "Usage", "#usage" %><%= toc.link "Sizes", "#sizes", indent: true %><% end %>').at_css("nav")
      assert_equal "lc-toc", toc["data-controller"]
      assert_equal "On this page", toc["aria-label"]
      assert_equal %w[#usage #sizes], toc.css("ul > li > a[data-lc-toc-target=link]").map { |link| link["href"] }
      assert toc.at_css("> [data-lc-toc-target=indicator][aria-hidden=true]")
      assert_nil toc.at_css("ul > span")

      headings = fragment(@view.lc_toc(headings: '<h2 id="a">A</h2><h3 id="b">B</h3><h4 id="c">C</h4><h2>No id</h2>'))
      links = headings.css("a")
      assert_equal %w[#a #b], links.map { |link| link["href"] }
      assert_equal %w[A B], links.map(&:text)
      assert_includes links.last["class"], "ps-[calc(var(--spacing-content)*2)]"

      assert_raises(ArgumentError) { @view.lc_toc }
      assert_raises(ArgumentError) { @view.lc_toc(headings: "<h2 id=a>A</h2>") { "" } }
      assert_raises(ActionView::Template::Error) { render('<%= lc_toc do |toc| %><%= toc.link "Usage", "/usage" %><% end %>') }
    end

    test "the docs shell holds the sidebar, a phone menu, the page and the contents" do
      html = render('<%= lc_docs_shell navigation: tag.nav("Links"), contents: tag.nav("Contents"), main: { class: "max-w-4xl" } do %>Page<% end %>')
      shell = html.at_css("[data-slot=docs-shell]")
      sidebar = shell.at_css("aside[data-slot=docs-shell-sidebar]")
      assert_equal "Documentation sidebar", sidebar["aria-label"]
      assert_equal "lc-scroll-keeper", sidebar["data-controller"]
      main = shell.at_css("main#main")
      assert_includes main["class"].split, "max-w-4xl"
      assert_equal "Menu", main.at_css("details summary").text
      assert_equal "Links", main.at_css("details nav").text
      assert_includes main.text, "Page"
      assert_equal "Contents", shell.at_css("aside[data-slot=docs-shell-contents]").text

      bare = render('<%= lc_docs_shell navigation: tag.nav("Links") do %>Page<% end %>')
      assert_nil bare.at_css("[data-slot=docs-shell-contents]")
      assert_raises(ArgumentError) { @view.lc_docs_shell(navigation: nil) { "" } }
    end

    test "the app header lays out the brand, navigation and actions" do
      html = render(<<~ERB)
        <%= lc_app_header bar: { class: "max-w-5xl" } do |header| %>
          <%= header.brand "/", label: "Home" do %>Logo<% end %>
          <%= header.nav class: "max-sm:hidden" do |nav| %><%= nav.link "Docs", "/docs", current: true %><% end %>
          <%= header.actions do %><button>Search</button><% end %>
        <% end %>
      ERB
      header = html.at_css("header.lc-app-header[data-controller=lc-app-header]")
      assert_includes header["data-action"], "scroll@window->lc-app-header#scroll"
      bar = header.at_css("[data-slot=app-header-bar]")
      assert_includes bar["class"].split, "max-w-5xl"
      assert bar.at_css(".lc-app-header__glass[aria-hidden=true]")
      assert_equal "Home", bar.at_css("a[data-slot=app-header-brand]")["aria-label"]
      nav = bar.at_css("nav[data-layout=row][data-controller=lc-nav]")
      assert_equal "Main", nav["aria-label"]
      assert_equal "page", nav.at_css("a[href='/docs']")["aria-current"]
      assert_equal "Search", bar.at_css("[data-slot=app-header-actions] button").text
      assert_raises(ArgumentError) { @view.lc_app_header }
    end

    test "the dock holds the destinations, an action menu and its own space" do
      html = render(<<~ERB)
        <%= lc_dock do |dock| %>
          <%= dock.nav label: "Sections" do |nav| %><%= nav.link "Home", "/", icon: "home", current: true %><% end %>
          <%= dock.menu label: "Create" do |menu| %>
            <%= menu.action "New note", icon: "pencil-square", data: { action: "notes#add" } %>
            <%= menu.action "New project", icon: "rectangle-stack" %>
          <% end %>
        <% end %>
      ERB
      dock = html.at_css("[data-slot=dock][data-controller=lc-dock]")
      assert dock.at_css("nav.lc-dock__nav[data-layout=dock][aria-label=Sections]")
      menu = dock.at_css("[data-slot=dock-menu][data-controller=lc-menu]")
      trigger = menu.at_css("button[data-slot=dock-menu-trigger]")
      assert_equal "create-menu", trigger["aria-controls"]
      assert_equal "Create", trigger["aria-label"]
      actions = menu.css("#create-menu[role=menu] [role=menuitem]")
      assert_equal [ "New note", "New project" ], actions.map(&:text)
      assert_equal "lc-menu#close notes#add", actions.first["data-action"]
      assert_equal [ "--lc-dock-action-index: 1", "--lc-dock-action-index: 2" ], actions.map { |action| action["style"] }
      assert_equal "Close Create", menu.at_css(".lc-dock__scrim")["aria-label"]
      assert dock.at_css(".lc-dock__space[aria-hidden=true]")
    end
  end
end
