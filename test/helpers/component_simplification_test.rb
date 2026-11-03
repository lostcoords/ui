require "test_helper"

module Lostcoords::Ui
  class ComponentSimplificationTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    test "button class helpers use the same variants and defaults as rendered buttons" do
      %i[primary secondary outline ghost glass destructive].each do |variant|
        button = Nokogiri::HTML.fragment(@view.lc_button("Save", variant: variant)).at_css("button")
        assert_equal @view.lc_button_class(variant: variant), button["class"], variant.to_s
      end
      assert_equal @view.lc_button_class(variant: :primary), @view.lc_button_class
      assert_raises(ArgumentError) { @view.lc_button_class(variant: :missing) }
      assert_raises(ArgumentError) { @view.lc_button_class(size: :missing) }
    end

    test "the consolidated API removes the old decorative and layout wrappers" do
      refute_respond_to @view, :lc_icon_medallion_class
      %i[lc_status_pill lc_medallion lc_eyebrow lc_card_surface lc_form_card lc_sheet lc_pill_row lc_form_actions].each do |name|
        refute_respond_to @view, name
        refute_respond_to @view, "#{name}_class"
      end
    end

    test "decorative icons support both shapes and feedback tones" do
      html = @view.lc_icon_badge(icon: "check", shape: :circle, size: :sm, tone: :success)
      icon = Nokogiri::HTML.fragment(html).at_css("span")
      assert_includes icon["class"].split, "rounded-full"
      assert_includes icon["class"].split, "text-success"
      assert_equal "true", icon.at_css("svg")["aria-hidden"]
      assert_raises(ArgumentError) { @view.lc_icon_badge(icon: "check", shape: :missing) }
    end

    test "feedback components share the same tone vocabulary" do
      BadgeHelper::BADGE_TONES.each_key do |tone|
        assert @view.lc_alert("Feedback", tone: tone).present?
        assert @view.lc_toast("Feedback", tone: tone).present?
        assert @view.lc_badge("Feedback", tone: tone).present?
      end
    end

    test "large avatars have a distinct size" do
      refute_equal @view.lc_avatar_class(size: :md), @view.lc_avatar_class(size: :lg)
    end
  end
end
