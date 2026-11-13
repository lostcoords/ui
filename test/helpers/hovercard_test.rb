require "test_helper"

module Lostcoords::Ui
  class HovercardTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def render(erb) = Nokogiri::HTML.fragment(@view.render(inline: erb))

    test "a hover card wires its trigger and keeps the card out of the accessibility tree" do
      html = render(<<~ERB)
        <%= lc_hovercard content: tag.span("Ada", class: "card"), side: :top do |card| %><%= link_to "Ada", "/ada", **card %><% end %>
      ERB
      wrapper = html.at_css("[data-slot=hovercard][data-controller=lc-hovercard]")
      assert_equal "top", wrapper["data-side"]
      assert_nil wrapper["data-lc-hovercard-src-value"]
      assert_equal "trigger", html.at_css("a[href='/ada']")["data-lc-hovercard-target"]
      content = wrapper.at_css("> [data-slot=hovercard-content]")
      assert_equal "true", content["aria-hidden"]
      assert content.key?("data-loaded")
      assert content.at_css(".card")
    end

    test "a hover card with src: loads later and shows a skeleton until then" do
      html = render('<%= lc_hovercard src: "/people/1/card" do |card| %><%= link_to "Ada", "/ada", **card %><% end %>')
      assert_equal "/people/1/card", html.at_css("[data-slot=hovercard]")["data-lc-hovercard-src-value"]
      content = html.at_css("[data-slot=hovercard-content]")
      assert_not content.key?("data-loaded")
      assert content.at_css("[data-slot=hovercard-loading] [data-slot=skeleton]")
    end

    test "a hover card needs one source and a trigger" do
      assert_raises(ArgumentError) { @view.lc_hovercard(src: "/a", content: "b") { "x" } }
      assert_raises(ArgumentError) { @view.lc_hovercard { "x" } }
      assert_raises(ArgumentError) { @view.lc_hovercard(content: "b") }
      assert_raises(ArgumentError) { @view.lc_hovercard(content: "b", side: :left) { "x" } }
    end
  end
end
