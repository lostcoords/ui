require "test_helper"
require "lostcoords/ui/components"

module Lostcoords::Ui
  class RenderAttributesTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.helpers
    end

    test "attributes merge classes and preserve independent data and aria values" do
      defaults = { class: "p-2 text-sm", data: { controller: "lc-sheet", action: "click->lc-sheet#open", lc_sheet_detents_value: "fit" }, aria: { expanded: false } }
      custom = { "class" => [ "p-4", { "font-bold" => true, "hidden" => false } ], "data" => { "controller" => "analytics lc-sheet", "action" => "click->analytics#track click->lc-sheet#open" }, "aria" => { "label" => "Details" } }
      merged = @view.send(:lc_attributes, defaults, custom)

      assert_equal "text-sm p-4 font-bold", merged[:class]
      assert_equal "lc-sheet analytics", merged.dig(:data, :controller)
      assert_equal "click->lc-sheet#open click->analytics#track", merged.dig(:data, :action)
      assert_equal "fit", merged.dig(:data, :lc_sheet_detents_value)
      assert_equal false, merged.dig(:aria, :expanded)
      assert_equal "Details", merged.dig(:aria, :label)
      assert_equal "p-2 text-sm", defaults[:class]
      assert_equal "analytics lc-sheet", custom.dig("data", "controller")
    end

    test "callers cannot remove required controller and action tokens" do
      merged = @view.send(:lc_attributes, { data: { controller: "lc-sheet", action: "click->lc-sheet#open" } }, { data: { controller: nil, action: nil } })

      assert_equal "lc-sheet", merged.dig(:data, :controller)
      assert_equal "click->lc-sheet#open", merged.dig(:data, :action)
    end

    test "flat and nested HTML attributes share one merge boundary" do
      defaults = { data: { controller: "lc-sheet", lc_sheet_detents_value: "fit" }, aria: { label: "Default" } }
      custom = { "data-controller" => "analytics", data: { "lc-sheet-detents-value" => "large" }, "aria-label" => "Custom" }
      merged = @view.send(:lc_attributes, defaults, custom)
      document = Nokogiri::HTML.fragment(@view.tag.div(**merged))

      assert_equal "lc-sheet analytics", merged.dig(:data, :controller)
      assert_equal "large", merged.dig(:data, :lc_sheet_detents_value)
      assert_equal "Custom", document.at_css("div")["aria-label"]
      assert_equal 1, @view.tag.div(**merged).scan("aria-label=").size
      refute merged.key?(:"data-controller")
      refute merged.key?(:"aria-label")
    end

    test "Tailwind selectors survive HTML escaping exactly once" do
      merged = @view.send(:lc_attributes, { class: "[&_svg]:size-5" }, { class: [ "[&>span]:block", { 'before:content-["hello"]' => true } ] })
      html = @view.tag.div(**merged)
      node = Nokogiri::HTML.fragment(html).at_css("div")

      assert_includes node["class"].split, "[&_svg]:size-5"
      assert_includes node["class"].split, "[&>span]:block"
      assert_includes node["class"].split, 'before:content-["hello"]'
      refute_includes html, "&amp;amp;"
    end

    test "component reflection excludes private plumbing and style builders" do
      names = Components.all.map(&:name)

      assert_includes names, :lc_button
      refute_includes names, :lc_attributes
      refute_includes names, :lc_option!
      refute_includes names, :lc_button_class
      assert_empty Builders.all.map(&:name) & names
      assert_equal names.uniq, names
      assert Components.all.all? { |component| File.file?(component.path) && component.signature.start_with?(component.name.to_s) }
    end
  end
end
