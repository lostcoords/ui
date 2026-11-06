require "test_helper"

module Lostcoords::Ui
  class BadgeTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "pill badges are fully rounded with wider padding and keep their tone" do
      badge = Nokogiri::HTML.fragment(@view.lc_badge("You", tone: :primary, shape: :pill)).at_css("span")
      classes = badge["class"].split

      assert_equal "You", badge.text
      assert_equal "primary", badge["data-tone"]
      assert_includes classes, "rounded-full"
      assert_includes classes, "px-2.5"
      assert_includes classes, "text-primary"
      assert_not_includes classes, "rounded-lg"
      assert_not_includes classes, "px-2"
      assert_equal @view.lc_badge_class, @view.lc_badge_class(shape: :rounded)
      assert_raises(ArgumentError) { @view.lc_badge("You", shape: :circle) }
    end

    test "avatar sizes grow in order and keep the 0.7 sizes" do
      sizes = %i[xs sm md lg xl xxl].map { |size| avatar_size(@view.lc_avatar_class(size: size)) }

      assert_equal [ 5, 6.5, 8, 12, 24, 28 ], sizes
      assert_raises(ArgumentError) { @view.lc_avatar("AB", size: :"2xl") }
    end

    test "icon badge sizes keep the 0.7 sizes" do
      assert_equal [ 6.5, 10, 12, 14 ], %i[sm md lg xl].map { |size| icon_badge_size(@view.lc_icon_badge_class(size: size)) }
    end

    test "spacing steps size avatars and icon badges between the named sizes" do
      assert_equal [ 7, 11 ], [ 7, 11 ].map { |size| avatar_size(@view.lc_avatar_class(size: size)) }
      assert_equal [ 6, 7, 11 ], [ 6, 7, 11 ].map { |size| icon_badge_size(@view.lc_icon_badge_class(size: size)) }
      assert_raises(ArgumentError) { @view.lc_avatar("AB", size: 9) }
      assert_raises(ArgumentError) { @view.lc_icon_badge("🍜", size: 9) }
    end

    test "a plain icon badge drops the tile and enlarges the glyph" do
      classes = @view.lc_icon_badge_class(size: :lg, shape: :plain, tone: :success).split

      assert_includes classes, "bg-transparent"
      assert_includes classes, "rounded-none"
      assert_includes classes, "text-success"
      assert_includes classes, "[--lc-icon-badge-font-scale-default:0.875]"
      assert_not_includes classes, "bg-success-soft"
      assert_not_includes classes, "[--lc-icon-badge-font-scale-default:0.5]"
    end

    test "initials and icons scale from the effective size unless a font size is pinned" do
      avatar = @view.lc_avatar_class(size: :lg)
      badge = @view.lc_icon_badge_class(size: :lg)

      assert_includes avatar, "text-[length:var(--lc-avatar-font-size,calc(var(--lc-avatar-size,var(--lc-avatar-size-default,"
      assert_includes avatar, "[--lc-avatar-font-scale-default:0.333]"
      assert_includes badge, "text-[length:var(--lc-icon-badge-font-size,calc(var(--lc-icon-badge-size,var(--lc-icon-badge-size-default,"
      assert_includes badge, "[--lc-icon-badge-font-scale-default:0.5]"
    end

    test "icon badges hold an emoji or custom glyph instead of a library icon" do
      emoji = Nokogiri::HTML.fragment(@view.lc_icon_badge("🍜", aria: { hidden: true })).at_css("span[data-slot=icon-badge]")
      glyph = Nokogiri::HTML.fragment(@view.lc_icon_badge(size: :lg) { @view.tag.b("A") }).at_css("span[data-slot=icon-badge] b")

      assert_equal "🍜", emoji.text
      assert_equal "true", emoji["aria-hidden"]
      assert_nil emoji.at_css("svg")
      assert_equal "A", glyph.text
      assert_raises(ArgumentError) { @view.lc_icon_badge("🍜", icon: "folder") }
    end

    test "cards render as the element their content needs" do
      card = Nokogiri::HTML.fragment(@view.lc_card(as: :section, padding: :sm, class: "grid gap-4", aria: { label: "Totals" }) { "Total" }).at_css("section[data-slot=card]")

      assert_equal "Totals", card["aria-label"]
      assert_includes card["class"].split, "grid"
      assert_not_includes card["class"].split, "flex"
      assert_raises(ArgumentError) { @view.lc_card(as: :span) { "Total" } }
      assert_not_includes Nokogiri::HTML.fragment(@view.lc_card(padding: :none) { "List" }).at_css("div")["class"].split, "gap-inset"
    end

    private
      def avatar_size(classes) = classes[/--lc-avatar-size-default:--spacing\(([\d.]+)\)\]/, 1]&.to_f || 8

      def icon_badge_size(classes) = classes[/--lc-icon-badge-size-default:--spacing\(([\d.]+)\)\]/, 1]&.to_f || 10
  end
end
