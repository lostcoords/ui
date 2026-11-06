require "test_helper"

module Lostcoords::Ui
  class SearchTest < ActiveSupport::TestCase
    setup do
      @view = ActionController::Base.new.view_context
    end

    test "the trigger takes the attributes and opens a labelled full-screen dialog" do
      fragment = Nokogiri::HTML.fragment(@view.lc_search(label: "Search <projects>", class: "w-96", data: { turbo: false }) { @view.tag.p("Recent") })
      root = fragment.at_css("[data-slot=search]")
      trigger = fragment.at_css("[data-slot=search-trigger]")
      dialog = fragment.at_css("dialog")
      input = dialog.at_css("input[type=search]")

      assert_equal "lc-search", root["data-controller"]
      assert_equal "button", trigger["type"]
      assert_equal "Search <projects>", trigger["aria-label"]
      assert_includes trigger["class"].split, "w-96"
      assert_equal "false", trigger["data-turbo"]
      assert_equal "dialog", trigger["aria-haspopup"]
      assert_equal dialog["id"], trigger["aria-controls"]
      assert_equal "mod+k", trigger["data-lc-shortcut-keys-value"]
      assert_includes trigger["data-action"], "lc-search#open"
      assert_equal "Search <projects>", dialog["aria-label"]
      assert_equal "q", input["name"]
      assert_equal "Search <projects>", input["placeholder"]
      assert_equal "Recent", dialog.at_css("[data-slot=search-results] p").text
      assert_equal "status", dialog.at_css("[data-lc-search-target=status]")["role"]
      assert_equal [ "%{count} result", "%{count} results" ], [ root["data-lc-search-one-value"], root["data-lc-search-other-value"] ]
      assert_nil fragment.at_css("script, projects")
    end

    test "src makes the field a GET form that names the query parameter" do
      fragment = Nokogiri::HTML.fragment(@view.lc_search(label: "Search", src: "/search", param: "query", id: "site-search", shortcut: nil))
      form = fragment.at_css("form[role=search]")

      assert_equal "/search", form["action"]
      assert_equal "get", form["method"]
      assert_equal "query", form.at_css("input")["name"]
      assert_equal "/search", fragment.at_css("[data-slot=search]")["data-lc-search-src-value"]
      assert_equal "site-search", fragment.at_css("dialog")["id"]
      assert_nil fragment.at_css("[data-slot=search-trigger]")["data-lc-shortcut-keys-value"]
      assert_nil fragment.at_css("kbd, input[data-controller]")
    end

    test "groups and results render labelled sections of links" do
      html = @view.lc_search_group("People", id: "people") do
        @view.lc_search_result("Alex <Lee>", "/people/1", detail: "Designer", icon: "user", keywords: "alex@example.com")
      end
      group = Nokogiri::HTML.fragment(html).at_css("section")
      result = group.at_css("a")

      assert_equal "People", group["aria-label"]
      assert_equal "people", group["id"]
      assert_equal "People", group.at_css("[data-slot=search-group-title]").text
      assert_equal "/people/1", result["href"]
      assert_equal "result", result["data-lc-search-target"]
      assert_equal "alex@example.com", result["data-lc-search-keywords"]
      assert_equal "Alex <Lee>", result.at_css("[data-slot=search-result-title]").text
      assert_equal "Designer", result.at_css("[data-slot=search-result-detail]").text
      assert result.at_css("[data-slot=icon-badge]")
    end

    test "a result block replaces the title and detail" do
      result = Nokogiri::HTML.fragment(@view.lc_search_result(nil, "/x") { @view.tag.strong("Custom") }).at_css("a")

      assert_equal "Custom", result.at_css("strong").text
      assert_nil result.at_css("[data-slot=search-result-title], [data-lc-search-keywords], [data-slot=icon-badge]")
    end

    test "labels are required" do
      assert_raises(ArgumentError) { @view.lc_search(label: "") }
      assert_raises(ArgumentError) { @view.lc_search_group("") }
      assert_raises(ArgumentError) { @view.lc_search_result("", "/x") }
      assert_raises(ArgumentError) { @view.lc_search_result("Title", "") }
    end

    test "search carries its empty note and prompt" do
      fragment = Nokogiri::HTML.fragment(@view.lc_search(label: "Search", src: "/search", empty: "No results for %{query}", prompt: "Search your groups"))
      assert_equal "No results for %{query}", fragment.at_css("[data-slot=search]")["data-lc-search-empty-value"]
      prompt = fragment.at_css("[data-slot=search-prompt][data-lc-search-target=prompt]")
      assert_equal "Search your groups", prompt.text
      assert prompt.key?("hidden")
      assert_nil Nokogiri::HTML.fragment(@view.lc_search(label: "Search")).at_css("[data-slot=search-prompt]")
      assert_raises(ArgumentError) { @view.lc_search(label: "Search", empty: "") }
    end
  end
end
