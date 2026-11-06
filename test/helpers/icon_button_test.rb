require "test_helper"

module Lostcoords::Ui
  class IconButtonTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
      @view.request = ActionDispatch::TestRequest.create
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)

    test "icon buttons take a button variant and tone" do
      quiet = fragment(@view.lc_icon_button("Settings", icon: "cog-6-tooth")).at_css("button")
      assert_equal @view.lc_icon_button_class(shape: :circle), quiet["class"]
      assert_nil quiet["data-variant"]

      delete = fragment(@view.lc_icon_button_to("Delete", "/files/1", icon: "trash", method: :delete, variant: :outline, tone: :destructive, size: :sm)).at_css("button")
      assert_includes delete["class"].split, "text-destructive"
      assert_includes delete["class"].split, "border-[color-mix(in_oklab,var(--destructive)_32%,var(--border))]"
      assert_equal %w[outline destructive], [ delete["data-variant"], delete["data-tone"] ]
      link = fragment(@view.lc_icon_button_link_to("Back", "/", icon: "chevron-left", variant: :secondary)).at_css("a")
      assert_includes link["class"].split, "bg-(--lc-button-bg)"
      assert_raises(ArgumentError) { @view.lc_icon_button("X", icon: "x-mark", tone: :loud) }
    end

    test "a block replaces the icon with custom content" do
      button = fragment(@view.lc_icon_button("Account", size: :sm) { @view.tag.span("AL", class: "avatar") }).at_css("button[data-slot=icon-button]")
      assert_equal "Account", button["aria-label"]
      assert_equal "AL", button.at_css("span.avatar").text
      assert_nil button.at_css("svg")
      assert_raises(ArgumentError) { @view.lc_icon_button("Empty") }
    end

    test "icon button links keep the label and refuse to be disabled" do
      link = fragment(@view.lc_icon_button_link_to("Back", "/groups", icon: "chevron-left", class: "md:hidden")).at_css("a")
      assert_equal "/groups", link["href"]
      assert_equal "Back", link["aria-label"]
      assert_equal "icon-button", link["data-slot"]
      assert_includes link["class"].split, "md:hidden"
      assert link.at_css("svg[aria-hidden=true]")
      assert_raises(ArgumentError) { @view.lc_icon_button_link_to("Back", "/", icon: "x-mark", disabled: true) }
    end

    test "icon button forms keep Rails' method and form options" do
      html = fragment(@view.lc_icon_button_to("Delete", "/attachments/1", icon: "trash", method: :delete, form: { data: { turbo_confirm: "Sure?" } }))
      form = html.at_css("form")
      assert_equal "/attachments/1", form["action"]
      assert_equal "Sure?", form["data-turbo-confirm"]
      assert_equal "delete", form.at_css("input[name=_method]")["value"]
      assert_equal "Delete", form.at_css("button[type=submit]")["aria-label"]
    end

    test "buttons, links and button forms take block: for full width" do
      html = fragment(@view.lc_button("Save", block: true) + @view.lc_button_link_to("Open", "/", block: true) + @view.lc_button_to("Go", "/", block: true))
      assert html.css("button[data-slot=button], a[data-slot=button]").all? { it["class"].split.include?("w-full") }
      assert_equal 3, html.css("[data-slot=button]").size
    end
  end
end
