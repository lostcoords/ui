require "test_helper"

module Lostcoords::Ui
  class MenuTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
      @view.request = ActionDispatch::TestRequest.create
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)

    test "options render a leading icon or custom content hidden from assistive technology" do
      icon = fragment(@view.lc_menu_option("Rename", icon: "pencil")).at_css("[role=menuitem]")
      leading = icon.at_css("[data-slot=menu-item-leading]")
      assert_equal "true", leading["aria-hidden"]
      assert leading.at_css("svg")
      assert_equal "Rename", icon.text.strip

      emoji = fragment(@view.lc_menu_option("Sushi", leading: @view.tag.span("🍣"))).at_css("[data-slot=menu-item-leading]")
      assert_equal "🍣", emoji.text

      plain = fragment(@view.lc_menu_option("Copy")).at_css("[role=menuitem]")
      assert_nil plain.at_css("[data-slot=menu-item-leading]")
      assert_raises(ArgumentError) { @view.lc_menu_option("Both", icon: "pencil", leading: "x".html_safe) }
    end

    test "a hint adds a secondary line inside the accessible name" do
      option = fragment(@view.lc_menu_option("Euro", hint: "EUR")).at_css("[role=menuitem]")
      assert_equal "EUR", option.at_css("[data-slot=menu-item-hint]").text
      assert_equal "EuroEUR", option.text
    end

    test "checked options are menu radio items with a check mark" do
      html = fragment(@view.lc_menu_option("Euro", checked: true) + @view.lc_menu_option("Yen", checked: false))
      checked, unchecked = html.css("[role=menuitemradio]")
      assert_equal "true", checked["aria-checked"]
      assert_equal "false", unchecked["aria-checked"]
      assert checked.at_css("svg[aria-hidden=true]")
      assert_nil fragment(@view.lc_menu_option("Plain")).at_css("[aria-checked]")
      assert_raises(ArgumentError) { @view.lc_menu_option("Bad", checked: "yes") }
    end

    test "checkbox options are menu checkbox items that flip without closing the menu" do
      option = fragment(@view.lc_menu_option("Pinned", checkbox: true)).at_css("button[role=menuitemcheckbox]")
      assert_equal "false", option["aria-checked"]
      assert_equal "click->lc-menu#check", option["data-action"]
      assert option.at_css("svg[aria-hidden=true]")
      assert_equal "true", fragment(@view.lc_menu_option("Pinned", checkbox: true, checked: true)).at_css("[role=menuitemcheckbox]")["aria-checked"]
      assert_raises(ArgumentError) { @view.lc_menu_option("Pinned", checkbox: true, href: "/pins") }
    end

    test "trigger: false renders only the panel for a controller hosted elsewhere" do
      menu = fragment(@view.lc_menu(id: "row", label: "Row actions", trigger: false) { @view.lc_menu_option("Edit") })
      panel = menu.at_css("[data-slot=menu]")
      assert_equal "row", panel["id"]
      assert_equal "Row actions", panel["aria-label"]
      assert_nil panel["aria-labelledby"]
      assert_equal "popover", panel["data-lc-menu-target"]
      assert_nil menu.at_css("[data-controller], button[aria-haspopup]")

      popover = fragment(@view.lc_popover(id: "pay", label: "How to pay", title: "Pay Alex", trigger: false) { "Bank" }).at_css("[data-slot=popover]")
      assert_equal "dialog", popover["role"]
      assert_equal "pay-title", popover["aria-labelledby"]
      assert_equal "popover", popover["data-lc-popover-target"]
      assert_raises(ArgumentError) { @view.lc_menu(id: "row", trigger: false, wrapper_attributes: { class: "flex" }) { "" } }
    end

    test "a method renders a form so non-GET actions work from a menu" do
      html = fragment(@view.lc_menu_option("Leave", href: "/memberships/1", method: :delete, params: { reason: "moved" }, form: { data: { turbo_confirm: "Sure?" } }, tone: :destructive))
      form = html.at_css("form")
      assert_equal "/memberships/1", form["action"]
      assert_equal "Sure?", form["data-turbo-confirm"]
      assert_includes form["class"].split, "contents"
      assert_equal "delete", form.at_css("input[name=_method]")["value"]
      assert_equal "moved", form.at_css("input[name=reason]")["value"]
      button = form.at_css("button[role=menuitem]")
      assert_equal "destructive", button["data-tone"]
      assert_equal "click->lc-menu#close", button["data-action"]
      assert_raises(ArgumentError) { @view.lc_menu_option("Leave", method: :delete) }
    end

    test "an icon trigger is a quiet icon button named by the label" do
      html = fragment(@view.lc_menu(id: "row", label: "Actions for Alex", trigger: :icon, icon: "ellipsis-horizontal", trigger_attributes: { class: "ms-auto" }) { @view.lc_menu_option("Edit") })
      trigger = html.at_css("#row-trigger")
      assert_equal "Actions for Alex", trigger["aria-label"]
      assert_equal "menu", trigger["aria-haspopup"]
      assert_equal "row", trigger["aria-controls"]
      assert_equal "lc-menu#toggle", trigger["data-action"]
      assert_includes trigger["class"].split, "ms-auto"
      assert_includes trigger["class"].split, "aria-expanded:text-foreground"
      assert trigger.at_css("svg[aria-hidden=true]")
      assert_equal "row-trigger", html.at_css("#row")["aria-labelledby"]
    end

    test "trigger attributes reach the trigger without overriding its wiring" do
      trigger = fragment(@view.lc_menu(id: "acct", label: "Account", trigger: :icon, trigger_attributes: { title: "ada@example.com", data: { action: "other#thing" } }) { "Body" }).at_css("#acct-trigger")
      assert_equal "ada@example.com", trigger["title"]
      assert_equal "acct", trigger["aria-controls"]
      assert_includes trigger["data-action"], "lc-menu#toggle"
    end

    test "a trigger part renders its own element with the panel's wiring merged in" do
      html = fragment(@view.lc_menu(id: "members", label: "Member") do |menu|
        menu.trigger(class: "w-48", data: { action: "click->stats#track" }) { |attrs| @view.lc_select_trigger("All members", size: :sm, **attrs) }
        @view.lc_menu_option("Alex")
      end)
      trigger = html.at_css("button#members-trigger")
      assert_equal "select-trigger", trigger["data-slot"]
      assert_equal "All members", trigger.text
      assert_equal "menu", trigger["aria-haspopup"]
      assert_equal "false", trigger["aria-expanded"]
      assert_equal "members", trigger["aria-controls"]
      assert_equal "trigger", trigger["data-lc-menu-target"]
      assert_equal "click->stats#track lc-menu#toggle", trigger["data-action"]
      assert_includes trigger["class"].split, "w-48"
      assert_includes trigger["class"].split, "h-control-sm"
      assert_equal 1, html.css("button[aria-haspopup]").size
      assert_equal "members-trigger", html.at_css("#members")["aria-labelledby"]
      assert_equal "Alex", html.at_css("#members [role=menuitem]").text.strip

      popover = fragment(@view.lc_popover(id: "total", label: "Total") do |panel|
        panel.trigger { |attrs| @view.tag.button(type: "button", title: "Paid so far", **attrs) { "Total ¥3,000" } }
        "Body"
      end)
      trigger = popover.at_css("button#total-trigger")
      assert_equal "Paid so far", trigger["title"]
      assert_equal "dialog", trigger["aria-haspopup"]
      assert_equal "lc-popover#toggle", trigger["data-action"]
      assert_raises(ArgumentError) { @view.lc_menu(id: "m", label: "M") { |menu| menu.trigger } }

      erb = <<~ERB
        <%= lc_menu id: "cat", label: "Category" do |menu| %>
          <% menu.trigger do |attrs| %>
            <%= lc_select_trigger(**attrs) do %><strong>Food</strong><% end %>
          <% end %>
          <%= lc_menu_option "Travel" %>
        <% end %>
      ERB
      html = fragment(@view.render(inline: erb))
      assert_equal "Food", html.at_css("button#cat-trigger strong").text
      assert_nil html.at_css("#cat button[data-slot=select-trigger]")
    end

    test "wrapper attributes style the panel's root and keep its controller" do
      html = fragment(@view.lc_menu(id: "payer", label: "Payer", wrapper_attributes: { class: "flex min-w-0", data: { controller: "picker", role: "from" } }) { "" })
      root = html.at_css("div:has(> #payer)")
      assert_equal "picker lc-menu", root["data-controller"]
      assert_equal "from", root["data-role"]
      assert_includes root["class"].split, "flex"
      assert_not_includes root["class"].split, "inline-flex"

      popover = fragment(@view.lc_popover(id: "note", label: "Note") { "Body" })
      assert_equal "lc-popover", popover.at_css("div:has(> #note)")["data-controller"]
    end

    test "custom trigger content keeps the trigger wiring" do
      html = fragment(@view.lc_popover(id: "who", label: "Alex's profile", trigger: @view.tag.span("AL")) { "Body" })
      trigger = html.at_css("button#who-trigger")
      assert_equal "AL", trigger.text
      assert_equal "Alex's profile", trigger["aria-label"]
      assert_equal "dialog", trigger["aria-haspopup"]
      assert_equal "lc-popover#toggle", trigger["data-action"]
      assert_raises(ArgumentError) { @view.lc_menu(id: "m", trigger: :link) { "Body" } }
      assert_raises(ArgumentError) { @view.lc_menu(id: "m", trigger: :select) { "Body" } }
      assert_raises(ArgumentError) { @view.lc_menu(id: "m", trigger: "<b>raw</b>") { "Body" } }
    end
  end
end
