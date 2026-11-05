require "test_helper"

module Lostcoords::Ui
  class StructuresTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    test "native form controls preserve names values and selected options" do
      input = fragment(@view.lc_input(name: "project[name]", value: "One & two", type: "email", required: true, data: { test: "input" }))
      assert_equal "email", input.at_css("input")["type"]
      assert_equal "project[name]", input.at_css("input")["name"]
      assert_equal "One & two", input.at_css("input")["value"]
      assert input.at_css("input[required][data-test=input]")

      select = fragment(@view.lc_select([ [ "Private", "private" ], [ "Team", "team" ] ], name: "access", selected: "team"))
      assert_equal "access", select.at_css("select")["name"]
      assert_equal "team", select.at_css("option[selected]")["value"]
      assert_equal "A & B", fragment(@view.lc_textarea("A & B", name: "notes")).at_css("textarea").text.delete_prefix("\n")
    end

    test "fields label native controls and connect hints and errors" do
      html = @view.lc_field(label: "Email", id: "email", hint: "Work email", error: "Enter an email") do |control|
        @view.lc_input(name: "email", **control)
      end
      field = fragment(html)
      assert_equal "email", field.at_css("label")["for"]
      assert_equal "email-hint email-error", field.at_css("input")["aria-describedby"]
      assert_equal "true", field.at_css("input")["aria-invalid"]
      assert_equal "Enter an email", field.at_css("[role=alert]").text
    end

    test "dialog instances own distinct labels controls and required wiring" do
      first = @view.lc_dialog(id: "one", title: "First", data: { lc_dialog_target: "wrong", action: "custom#submit" }, "data-lc-dialog-target": "flat-wrong", aria: { labelledby: "wrong", describedby: "help" }) { @view.tag.p("First body") }
      second = @view.lc_dialog(id: "two", title: "Second") { "Second body" }
      dialogs = fragment(first + second)
      assert_equal [ "one", "two" ], dialogs.css("dialog").map { |node| node["id"] }
      assert_equal "one-title", dialogs.at_css("#one")["aria-labelledby"]
      assert_equal "help", dialogs.at_css("#one")["aria-describedby"]
      assert_equal "dialog", dialogs.at_css("#one")["data-lc-dialog-target"]
      assert_equal "one", dialogs.at_css("button[aria-controls=one]")["aria-controls"]
      assert_equal "First body", dialogs.at_css("#one p").text
      assert dialogs.at_css("button[data-action='lc-dialog#close'][aria-label='Close First']")
    end

    test "sheets preserve additional controllers and own detents" do
      sheet = fragment(@view.lc_dialog(id: "edit", title: "Edit", detents: "medium large", data: { controller: "validation" }) { "Body" })
      assert_equal "lc-sheet validation", sheet.at_css("dialog")["data-controller"]
      assert_equal "medium large", sheet.at_css("dialog")["data-lc-sheet-detents-value"]
      assert_equal "edit-title", sheet.at_css("dialog")["aria-labelledby"]
    end

    test "menus and popovers provide matching trigger and panel semantics" do
      menu = @view.lc_menu(id: "actions", label: "Project actions", data: { lc_menu_target: "wrong" }) { @view.lc_menu_option("Delete", tone: "destructive", data: { action: "project#delete" }) }
      popup = @view.lc_popover(id: "settings", label: "Settings", title: "Preferences", trigger_variant: :ghost) { @view.lc_input(name: "theme") }
      html = fragment(menu + popup)
      assert_equal "menu", html.at_css("#actions")["role"]
      assert_equal "popover", html.at_css("#actions")["data-lc-menu-target"]
      assert_equal "actions-trigger", html.at_css("#actions")["aria-labelledby"]
      assert_equal "lc-menu#toggle", html.at_css("#actions-trigger")["data-action"]
      assert_equal "click->lc-menu#close project#delete", html.at_css("[role=menuitem]")["data-action"]
      assert_equal "dialog", html.at_css("#settings")["role"]
      assert_equal "-1", html.at_css("#settings")["tabindex"]
      assert_equal "settings-title", html.at_css("#settings")["aria-labelledby"]
      assert_equal "lc-popover#toggle", html.at_css("#settings-trigger")["data-action"]
      assert_includes html.at_css("#settings-trigger")["class"].split, "bg-transparent"
      assert_nil html.at_css("#settings")["trigger_variant"]
    end

    test "an optional blank popover title falls back to its trigger label" do
      [ nil, "", "   " ].each do |title|
        popover = fragment(@view.lc_popover(id: "preferences", label: "Preferences", title: title) { "Content" })
        assert_equal "preferences-trigger", popover.at_css("#preferences")["aria-labelledby"]
        assert_equal "Preferences", popover.at_css("#preferences-trigger").text
        assert_nil popover.at_css("h2")
      end
    end

    test "selections and pills own interactive states without submitting forms" do
      html = @view.lc_toggle_group(label: "Period", name: "period", value: "month", data: { controller: "analytics" }) do
        @view.safe_join([ @view.lc_toggle_group_item("Month", value: "month", selected: true), @view.lc_toggle_group_item("Year", value: "year") ])
      end
      group = fragment(html)
      assert_equal "lc-selection analytics", group.at_css("[role=group]")["data-controller"]
      assert_equal "month", group.at_css("input[name=period]")["value"]
      assert_equal [ "button", "button" ], group.css("button").map { |button| button["type"] }
      assert_equal [ "true", "false" ], group.css("button").map { |button| button["aria-pressed"] }
      pill = fragment(@view.lc_toggle("Design", active: true, data: { action: "filters#change" }))
      assert_equal "lc-toggle", pill.at_css("button")["data-controller"]
      assert_equal "click->lc-toggle#toggle filters#change", pill.at_css("button")["data-action"]
      link = fragment(@view.lc_button_link_to("Current", "/projects", aria: { current: "page" }))
      assert_equal "page", link.at_css("a")["aria-current"]
      assert_nil link.at_css("a")["aria-pressed"]
    end

    test "toasts and disclosures own accessible native structure" do
      toast = fragment(@view.lc_toast("Saved", timeout: 6000, tone: :destructive))
      assert_equal "alert", toast.at_css("div")["role"]
      assert_equal "6000", toast.at_css("div")["data-lc-toast-timeout-value"]
      assert_equal "click->lc-toast#dismiss", toast.at_css("div")["data-action"]
      assert_equal "0", fragment(@view.lc_toast("Persistent", timeout: 0)).at_css("[data-controller=lc-toast]")["data-lc-toast-timeout-value"]
      disclosure = fragment(@view.lc_collapsible(title: "Details", open: true) { @view.tag.p("Body") })
      assert disclosure.at_css("details[open]")
      assert_equal "Details", disclosure.at_css("summary").text
      assert_equal "Body", disclosure.at_css("details > div p").text
      assert_equal "click->lc-collapsible#toggle", disclosure.at_css("details")["data-action"]
    end

    test "emoji pickers preserve Rails form names and extend runtime attributes" do
      form = ActionView::Helpers::FormBuilder.new(:project, nil, @view, {})
      html = fragment(@view.lc_emoji_picker(form: form, field: :emoji, label: "Choose a symbol", catalog_url: "/emoji-catalog", quick: [ "✨" ], id: "symbol", data: { controller: "autosave", action: "change->autosave#save" }))
      assert_equal "lc-emoji-picker autosave", html.at_css("#symbol")["data-controller"]
      assert_equal "project[emoji]", html.at_css("input[type=hidden]")["name"]
      assert_equal "/emoji-catalog", html.at_css("#symbol")["data-lc-emoji-picker-catalog-url-value"]
      assert_equal "change->autosave#save", html.at_css("#symbol")["data-action"]
    end

    test "unsupported options and missing accessible labels are rejected" do
      assert_raises(ArgumentError) { @view.lc_input(size: :tiny) }
      assert_raises(ArgumentError) { @view.lc_input(type: :unsupported) }
      assert_raises(ArgumentError) { @view.lc_select(size: :tiny) }
      assert_raises(ArgumentError) { @view.lc_dialog_class(:nope) }
      assert_raises(ArgumentError) { @view.lc_popover_class(align: :left) }
      assert_raises(ArgumentError) { @view.lc_menu_option_class(tone: :loud) }
      assert_raises(ArgumentError) { @view.lc_glass_class(shape: :blob) }
      assert_raises(ArgumentError) { @view.lc_sheet_data(detents: "huge") }
      assert_raises(ArgumentError) { @view.lc_tabs(id: "t", label: "T") { |tabs| tabs.panel("a b") { "1" }; tabs.panel("a-b") { "2" } } }
      assert_raises(ArgumentError) { @view.lc_dialog(id: "", title: "Dialog") { "Body" } }
      assert_raises(ArgumentError) { @view.lc_dialog(id: "lc-sheet", title: "Sheet", detents: "short") { "Body" } }
      assert_raises(ArgumentError) { @view.lc_menu(id: "menu", align: :middle) { "Body" } }
      assert_raises(ArgumentError) { @view.lc_toast("Saved", timeout: -1) }
      assert_raises(ArgumentError) { @view.lc_toast("Saved", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_toggle("Disabled link", href: "/", disabled: true) }
      assert_raises(ArgumentError) { @view.lc_toggle("Disabled link", href: "/", **{ "disabled" => true }) }
      assert_raises(ArgumentError) { @view.lc_menu_option("Disabled link", href: "/", **{ "disabled" => true }) }
      assert_raises(ArgumentError) { @view.lc_toggle("Legacy size", size: :nav) }
      assert_raises(ArgumentError) { @view.lc_input(type: :checkbox) }
    end

    private

    def fragment(html)
      Nokogiri::HTML.fragment(html)
    end
  end
end
