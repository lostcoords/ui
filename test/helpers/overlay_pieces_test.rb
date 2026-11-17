require "test_helper"

module Lostcoords::Ui
  class OverlayPiecesTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    test "an avatar badge is a decorative mark, a named button or a label for a hidden input" do
      mark = fragment(@view.lc_avatar_badge("lock-closed")).at_css("[data-slot=avatar-badge]")
      assert_equal "span", mark.name
      assert_equal "true", mark["aria-hidden"]
      assert_includes mark["class"].split, "size-7"

      button = fragment(@view.lc_avatar_badge("camera", label: "Photo", as: :button, aria: { haspopup: "menu" })).at_css("button")
      assert_equal "button", button["type"]
      assert_equal "Photo", button["aria-label"]
      assert_equal "menu", button["aria-haspopup"]
      assert_includes button["class"].split, "size-11"

      label = fragment(@view.lc_avatar_badge("camera", label: "Upload", as: :label, for: "user_avatar")).at_css("label")
      assert_equal "user_avatar", label["for"]
      assert_equal "Upload", label.at_css(".sr-only").text

      assert_raises(ArgumentError) { @view.lc_avatar_badge("camera", as: :button) }
      assert_raises(ArgumentError) { @view.lc_avatar_badge("camera", label: "Upload", as: :label) }
      assert_raises(ArgumentError) { @view.lc_avatar_badge("camera", label: "Photo", as: :button, size: :sm) }
    end

    test "a file drop is a label around a hidden file input with its title hint and button" do
      drop = fragment(@view.lc_file_drop(name: "files", title: "Add files", hint: "Up to 10 MB", button: "Browse", accept: ".csv", multiple: true,
        input: { data: { action: "change->upload#update" } })).at_css("label[data-slot=file-drop]")
      input = drop.at_css("input[type=file]")
      assert_equal ".csv", input["accept"]
      assert input.key?("multiple")
      assert_includes input["class"].split, "sr-only"
      assert_equal "change->upload#update", input["data-action"]
      assert_equal "Add files", drop.at_css("[data-slot=file-drop-title]").text
      assert_equal "Up to 10 MB", drop.at_css("[data-slot=file-drop-hint]").text
      assert_equal "true", drop.at_css("[data-slot=button]")["aria-hidden"]
      assert_raises(ArgumentError) { @view.lc_file_drop(title: "Add files") }
    end

    test "a form builder file drop wraps the attribute's file field" do
      html = @view.render(inline: '<%= lc_form_with url: "/x", scope: :import do |f| %><%= f.file_drop :file, title: "CSV", accept: ".csv" %><% end %>')
      input = fragment(html).at_css("label[data-slot=file-drop] input[type=file]")
      assert_equal "import[file]", input["name"]
      assert_includes input["class"].split, "sr-only"
    end

    test "an input with an icon wraps the field and keeps attributes on the input" do
      group = fragment(@view.lc_input(type: :search, icon: "magnifying-glass", class: "rounded-full", aria: { label: "Search" })).at_css("[data-slot=input-group]")
      assert_equal "true", group.at_css("svg")["aria-hidden"]
      input = group.at_css("input")
      assert_equal "Search", input["aria-label"]
      assert_includes input["class"].split, "ps-10"
      assert_includes input["class"].split, "rounded-full"
      assert_raises(ArgumentError) { @view.lc_input(icon: "magnifying-glass", plain: true) }
    end

    test "a glass sheet takes the menu material and its parts stay pinned" do
      html = @view.render(inline: "<%= lc_sheet surface: :glass do |sheet| %><%= sheet.header do %>Title<% end %>Body<%= sheet.footer do %>Save<% end %><% end %>")
      sheet = fragment(html).at_css("[data-slot=sheet]")
      assert_includes sheet["class"].split, "lc-glass"
      assert_includes sheet.at_css("[data-slot=sheet-header]")["class"].split, "sticky"
      assert_includes sheet.at_css("[data-slot=sheet-footer]")["class"].split, "bottom-0"
      assert_raises(ArgumentError) { @view.lc_sheet(as: :dialog, surface: :glass) }
    end

    test "a heading can render as a span" do
      span = fragment(@view.lc_heading("¥4,500", as: :span, size: :title)).at_css("span")
      assert_includes span["class"].split, "text-title"
      assert_raises(ArgumentError) { @view.lc_heading("x", as: :p) }
    end

    private
      def fragment(html) = Nokogiri::HTML.fragment(html)
  end
end
