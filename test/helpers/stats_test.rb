require "test_helper"

module Lostcoords::Ui
  class StatsTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)
    def render(erb) = fragment(@view.render(inline: erb))

    test "stats are a description list, each label before its value" do
      list = render(<<~ERB).at_css("dl[data-slot=stats]")
        <%= lc_stats class: "justify-end" do %>
          <%= lc_stat "1,204", label: "replies sent", tone: :primary %>
          <%= lc_stat label: "people" do %><a href="/people">96</a><% end %>
        <% end %>
      ERB
      assert_equal "inline", list["data-layout"]
      assert_includes list["class"].split, "justify-end"
      stats = list.css("> div[data-slot=stat]")
      assert_equal [ %w[dt dd], %w[dt dd] ], stats.map { |stat| stat.element_children.map(&:name) }
      assert_equal [ "replies sent", "people" ], stats.map { |stat| stat.at_css("dt[data-slot=stat-label]").text }
      assert_equal "1,204", stats[0].at_css("dd[data-slot=stat-value]").text
      assert_includes stats[0].at_css("dd")["class"].split, "text-primary"
      assert_equal "primary", stats[0]["data-tone"]
      assert_nil stats[1]["data-tone"]
      assert_equal "/people", stats[1].at_css("dd a")["href"]
      assert_includes stats[0].at_css("dd")["class"].split, "tabular-nums"
    end

    test "the grid layout gives each stat a tile in columns" do
      list = render('<%= lc_stats layout: :grid, columns: 2 do %><%= lc_stat 3, label: "Likes" %><% end %>').at_css("dl")
      assert_equal "grid", list["data-layout"]
      assert_includes list["class"].split, "grid-cols-2"
      assert_includes list.at_css("[data-slot=stat]")["class"].split, "group-data-[layout=grid]/stats:bg-tile"

      auto = render('<%= lc_stats layout: :grid do %><%= lc_stat 3, label: "Likes" %><% end %>').at_css("dl")
      assert_includes auto["class"], "auto-fit"
    end

    test "stats reject unknown options" do
      assert_raises(ArgumentError) { @view.lc_stats(columns: 2) { "" } }
      assert_raises(ArgumentError) { @view.lc_stats(layout: :grid, columns: 5) { "" } }
      assert_raises(ArgumentError) { @view.lc_stats(layout: :list) { "" } }
      assert_raises(ArgumentError) { @view.lc_stat(1, label: "Likes", tone: :like) }
      assert_raises(ArgumentError) { @view.lc_stat(1, label: "") }
      assert_raises(ArgumentError) { @view.lc_stat(label: "Likes") }
    end
  end
end
