require "test_helper"

module Lostcoords::Ui
  class CharCounterTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def counter(**options) = Nokogiri::HTML.fragment(@view.lc_char_counter(**options)).at_css("[data-slot=char-counter]")

    test "an empty counter is hidden and wired to its field" do
      ring = counter(max: 280, for: "post")
      assert ring["hidden"]
      assert_equal "img", ring["role"]
      assert_equal "0 of 280 characters", ring["aria-label"]
      assert_equal "lc-char-counter", ring["data-controller"]
      assert_equal "280", ring["data-lc-char-counter-max-value"]
      assert_equal "20", ring["data-lc-char-counter-warn-value"]
      assert_equal "post", ring["data-lc-char-counter-for-value"]
      assert_equal "%{count} of %{max} characters", ring["data-lc-char-counter-label-value"]
      assert_nil ring["data-lc-char-counter-count-value"]
      assert_equal "true", ring.at_css("svg")["aria-hidden"]
      assert ring.at_css("circle[data-lc-char-counter-target=progress]")
      assert_equal "", ring.at_css("[data-lc-char-counter-target=remaining]").text
    end

    test "count: renders the state before JavaScript runs" do
      calm = counter(max: 280, count: 100)
      assert_nil calm["hidden"]
      assert_equal "ok", calm["data-state"]
      assert_equal "100", calm["data-lc-char-counter-count-value"]
      assert_equal "", calm.at_css("[data-slot=char-counter-remaining]").text

      near = counter(max: 280, count: 265)
      assert_equal "near", near["data-state"]
      assert_equal "15", near.at_css("[data-slot=char-counter-remaining]").text

      over = counter(max: 280, count: 290, warn: 5)
      assert_equal "over", over["data-state"]
      assert_equal "-10", over.at_css("[data-slot=char-counter-remaining]").text
      assert_equal "290 of 280 characters", over["aria-label"]
      assert_includes over["class"].split, "data-[state=over]:text-destructive"
    end

    test "the label is translated" do
      I18n.with_locale(:ja) { assert_equal "280文字中12文字", counter(max: 280, count: 12)["aria-label"] }
    end

    test "max, warn and count must be integers" do
      assert_raises(ArgumentError) { counter(max: 0) }
      assert_raises(ArgumentError) { counter(max: "280") }
      assert_raises(ArgumentError) { counter(max: 280, warn: -1) }
      assert_raises(ArgumentError) { counter(max: 280, count: "3") }
    end
  end
end
