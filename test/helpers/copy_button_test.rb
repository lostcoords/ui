require "test_helper"

module Lostcoords::Ui
  class CopyButtonTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "copy buttons escape text and expose native semantics and outcome feedback" do
      html = @view.lc_copy_button("Copy <link>", value: "<script>unsafe</script>", copied_label: "<Copied>", class: "w-full", data: { controller: "analytics", action: "click->analytics#track" }, aria: { describedby: "hint" }, type: :submit)
      fragment = Nokogiri::HTML.fragment(html)
      button = fragment.at_css("button")

      assert_equal "button", button["type"]
      assert_equal "Copy <link>", button["aria-label"]
      assert_equal "hint", button["aria-describedby"]
      assert_includes button["class"].split, "w-full"
      assert_equal "analytics", button["data-controller"]
      assert_includes button["data-action"], "ui-copy#copy"
      assert_includes button["data-action"], "click->analytics#track"
      assert_equal "<script>unsafe</script>", fragment.at_css("[data-ui-copy-value-value]")["data-ui-copy-value-value"]
      assert_nil fragment.at_css("script, link, copied")
      assert_equal [ "Copy <link>", "<Copied>", "Retry" ], button.css("[data-copy-state]").map { |node| node.text.strip }
      assert button.css("[data-copy-state]").all? { |node| node["aria-hidden"] == "true" }
      assert_equal "true", fragment.at_css('[role="status"]')["aria-atomic"]
      assert_equal "", fragment.at_css('[role="status"]').text
    end

    test "a source reference has a named icon-only button and retains disabled state" do
      fragment = Nokogiri::HTML.fragment(@view.lc_copy_button("Copy code", source: "snippet", icon_only: true, size: :sm, disabled: true, reset_after: 3000))
      assert_equal "snippet", fragment.at_css("[data-ui-copy-source-value]")["data-ui-copy-source-value"]
      assert_nil fragment.at_css("[data-ui-copy-value-value]")
      assert_equal "3000", fragment.at_css("[data-ui-copy-reset-after-value]")["data-ui-copy-reset-after-value"]
      button = fragment.at_css("button")
      assert_equal "Copy code", button["aria-label"]
      assert_equal "disabled", button["disabled"]
      assert_equal "", button.text.strip
      assert_equal 3, button.css("svg").size
      assert_includes button["class"].split, "size-11"
    end

    test "copy labels use the current locale" do
      I18n.with_locale(:ja) do
        fragment = Nokogiri::HTML.fragment(@view.lc_copy_button(value: "text"))
        assert_equal "コピー", fragment.at_css("button")["aria-label"]
        assert_equal "コピー済み", fragment.at_css('[data-copy-state="copied"]').text.strip
      end
    end

    test "copy buttons reject ambiguous sources and invalid reset times or names" do
      assert_raises(ArgumentError) { @view.lc_copy_button }
      assert_raises(ArgumentError) { @view.lc_copy_button(value: "text", source: "snippet") }
      assert_raises(ArgumentError) { @view.lc_copy_button(source: " ") }
      [ 0, -1, Float::INFINITY, Float::NAN, "2000" ].each do |reset_after|
        assert_raises(ArgumentError) { @view.lc_copy_button(value: "text", reset_after: reset_after) }
      end
      assert_raises(ArgumentError) { @view.lc_copy_button("", value: "text") }
      assert_raises(ArgumentError) { @view.lc_copy_button(value: "text", "aria-label": "") }
      assert_raises(ArgumentError) { @view.lc_copy_button(value: "text", size: :missing) }
      assert_raises(ArgumentError) { @view.lc_copy_button(value: "text", variant: :missing) }
      assert_equal "", Nokogiri::HTML.fragment(@view.lc_copy_button(value: "")).at_css("[data-ui-copy-value-value]")["data-ui-copy-value-value"]
    end
  end
end
