require "test_helper"

module Lostcoords::Ui
  class IconTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Helpers)
    end

    test "all upstream variants render SVG with explicit accessible attributes" do
      { outline: "24", solid: "24", mini: "20", micro: "16" }.each do |variant, size|
        svg = Nokogiri::HTML.fragment(@view.lc_icon("check", variant: variant, options: { class: "size-5", aria: { hidden: true } })).at_css("svg")
        assert_equal "0 0 #{size} #{size}", svg["viewbox"]
        assert_includes svg["class"].split, "lc-icon"
        assert_includes svg["class"].split, "size-5"
        assert_equal "true", svg["aria-hidden"]
        assert svg.at_css("path")
      end
    end

    test "attribute values are escaped without mutating later renders" do
      label = %q{a" onload="alert(1)}
      svg = Nokogiri::HTML.fragment(@view.lc_icon("check", options: { aria: { label: label } }, path_options: { "stroke-linecap": "square" })).at_css("svg")
      assert_equal label, svg["aria-label"]
      assert_nil svg["onload"]
      assert_equal "square", svg.at_css("path")["stroke-linecap"]
      assert_equal "round", Nokogiri::HTML.fragment(@view.lc_icon("check")).at_css("path")["stroke-linecap"]
      assert_nil Nokogiri::HTML.fragment(@view.lc_icon("check")).at_css("svg")["aria-label"]
    end

    test "unknown names and variants fail without consulting Rails or the filesystem" do
      assert_raises(ArgumentError) { @view.lc_icon("../../secrets") }
      assert_raises(ArgumentError) { @view.lc_icon("check", variant: :unknown) }
    end

    test "Ruby-style SVG attribute names retain the wrapper's dashed attribute behavior" do
      svg = Nokogiri::HTML.fragment(@view.lc_icon("check", options: { stroke_width: 3, aria_label: "Done", data: { test: "icon" } })).at_css("svg")
      assert_equal "3", svg["stroke-width"]
      assert_equal "Done", svg["aria-label"]
      assert_equal "icon", svg["data-test"]
      assert_nil svg["stroke_width"]
    end
  end
end
