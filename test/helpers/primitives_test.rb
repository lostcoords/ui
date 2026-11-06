require "test_helper"

module Lostcoords::Ui
  class PrimitivesTest < ActiveSupport::TestCase
    setup do
      @view = ActionView::Base.empty.extend(Lostcoords::Ui::Engine.helpers)
    end

    test "buttons are escaped native controls and accept normal attributes" do
      button = fragment(@view.lc_button("<Save>", disabled: true, name: "intent", value: "save", class: [ "px-9", { "w-full" => true } ], data: { controller: "save", action: "click->save#run" }, aria: { describedby: "hint" })).at_css("button")

      assert_equal "button", button["type"]
      assert_equal "<Save>", button.text
      assert_nil button.at_css("save")
      assert_equal "disabled", button["disabled"]
      assert_equal "intent", button["name"]
      assert_equal "save", button["value"]
      assert_includes button["class"].split, "px-9"
      assert_not_includes button["class"].split, "px-5"
      assert_includes button["class"].split, "w-full"
      assert_equal "save", button["data-controller"]
      assert_equal "click->save#run", button["data-action"]
      assert_equal "hint", button["aria-describedby"]
    end

    test "button icons are decorative and their position sets the optical spacing contract" do
      button = fragment(@view.lc_button("Create", icon: "plus")).at_css("button")
      assert_equal "inline-start", button.at_css("svg")["data-icon"]
      assert_equal "true", button.at_css("svg")["aria-hidden"]
      assert_equal "svg", button.element_children.first.name
      assert_equal "Create", button.text.strip

      link = fragment(@view.lc_button_link_to("Next", "/next", icon: "arrow-right", icon_position: :end)).at_css("a")
      assert_equal "inline-end", link.element_children.last["data-icon"]
      assert_equal "/next", link["href"]
      html = @view.lc_button(icon: "plus") { @view.tag.strong("Create") }
      assert_equal "Create", fragment(html).at_css("button strong").text
      assert_raises(ArgumentError) { @view.lc_button("Create", icon: "plus", icon_position: :left) }
    end

    test "button blocks preserve markup and explicit submit type" do
      html = @view.lc_button(type: "submit") { @view.tag.strong("Save") }
      assert_equal "Save", fragment(html).at_css('button[type="submit"] strong').text
    end

    test "a span button keeps the look without being a control" do
      span = fragment(@view.lc_button("Browse", as: :span, size: :sm, aria: { hidden: true })).at_css("span")
      assert_equal @view.lc_button_class(size: :sm), span["class"]
      assert_equal "true", span["aria-hidden"]
      assert_equal "button", span["data-slot"]
      assert_nil span["type"]
      assert_raises(ArgumentError) { @view.lc_button("Browse", as: :a) }
    end

    test "a button with expanded_icon keeps its label as the name and swaps in the icon while expanded" do
      button = fragment(@view.lc_button("Add", icon: "plus", expanded_icon: "x-mark", size: :sm, class: "group/add", aria: { expanded: false })).at_css("button")
      label = button.at_css("[data-slot=button-label]")
      assert_equal "Add", label.text.strip
      assert label.at_css("svg[data-icon=inline-start]")
      swap = button.at_css("svg[data-slot=button-expanded-icon]")
      assert_equal "true", swap["aria-hidden"]
      assert_includes button["class"].split, "[&>[data-slot=button-expanded-icon]]:hidden"
      assert_includes button["class"].split, "aria-expanded:[&>[data-slot=button-label]]:sr-only"
      assert_includes button["class"].split, "group/add"
    end

    test "public button variants and sizes are strict and accept strings" do
      html = @view.lc_button("Remove", variant: "destructive", size: "sm")
      assert_includes fragment(html).at_css("button")["class"].split, "[--lc-button-bg:color-mix(in_oklab,var(--destructive)_60%,black)]"
      assert_includes fragment(@view.lc_button("More", variant: "outline")).at_css("button")["class"].split, "border-border"
      assert_includes fragment(@view.lc_button("More", variant: "glass")).at_css("button")["class"].split, "lc-glass"

      { variant: :accent, size: :nav }.each do |name, value|
        error = assert_raises(ArgumentError) { @view.lc_button("Save", **{ name => value }) }
        assert_includes error.message, name.to_s
      end
      assert_raises(ArgumentError) { @view.lc_badge("New", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_icon_badge(icon: "check", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_icon_badge(icon: "check", size: :missing) }
      assert_raises(ArgumentError) { @view.lc_avatar("AB", size: nil) }
      assert_raises(ArgumentError) { @view.lc_card(padding: :missing) }
      assert_raises(ArgumentError) { @view.lc_badge("New", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_spinner(size: :missing) }
      assert_raises(ArgumentError) { @view.lc_alert("Oops", tone: :missing) }
    end

    test "button links preserve native navigation and block forms" do
      link = fragment(@view.lc_button_link_to("Read", "/guide", target: "_blank", rel: "noopener")).at_css("a")
      assert_equal "/guide", link["href"]
      assert_equal "_blank", link["target"]
      assert_nil link["type"]

      html = @view.lc_button_link_to("/guide") { @view.tag.em("Guide") }
      assert_equal "Guide", fragment(html).at_css('a[href="/guide"] em').text
      assert_raises(ArgumentError) { @view.lc_button_link_to("Read", "/guide", disabled: true) }
      assert_raises(ArgumentError) { @view.lc_button_link_to("Read", "/guide", "disabled" => true) }
    end

    test "button_to preserves form HTTP and CSRF behavior" do
      @view.define_singleton_method(:protect_against_forgery?) { true }
      @view.define_singleton_method(:form_authenticity_token) { |**| "csrf-token" }
      @view.define_singleton_method(:request_forgery_protection_token) { :authenticity_token }

      html = @view.lc_button_to("Delete", "/entries/1", method: :delete, params: { return_to: "/entries" }, form: { data: { turbo_confirm: "Delete?" } }, class: "w-full")
      form = fragment(html).at_css("form")
      assert_equal "/entries/1", form["action"]
      assert_equal "post", form["method"]
      assert_equal "Delete?", form["data-turbo-confirm"]
      assert_equal "delete", form.at_css('input[name="_method"]')["value"]
      assert_equal "csrf-token", form.at_css('input[name="authenticity_token"]')["value"]
      assert_equal "/entries", form.at_css('input[name="return_to"]')["value"]
      assert_equal "submit", form.at_css("button")["type"]
      assert_includes form.at_css("button")["class"].split, "w-full"

      html = @view.lc_button_to("/entries", method: :post) { @view.tag.strong("Create") }
      assert_equal "Create", fragment(html).at_css('form[action="/entries"] button strong').text
    end

    test "icon buttons have accessible names and decorative icons" do
      button = fragment(@view.lc_icon_button("Close", icon: "x-mark")).at_css("button")
      assert_equal "button", button["type"]
      assert_equal "Close", button["aria-label"]
      assert_equal "true", button.at_css("svg")["aria-hidden"]
      assert_raises(ArgumentError) { @view.lc_icon_button("  ", icon: "x-mark") }
      assert_raises(ArgumentError) { @view.lc_icon_button(nil, icon: "x-mark") }
      assert_raises(ArgumentError) { @view.lc_icon_button("Close", icon: "x-mark", aria: { label: "" }) }
      assert_raises(ArgumentError) { @view.lc_icon_button("Close", icon: "x-mark", "aria-label": "") }
      assert_raises(ArgumentError) { @view.lc_icon_button("Close", icon: "x-mark", shape: :missing) }
    end

    test "a destructive tone recolours a variant without changing its emphasis" do
      ghost = fragment(@view.lc_button("Revoke", variant: :ghost, tone: "destructive")).at_css("button")
      classes = ghost["class"].split
      assert_equal "destructive", ghost["data-tone"]
      assert_includes classes, "bg-transparent"
      assert_includes classes, "text-destructive"
      assert_not_includes classes, "text-muted-foreground"

      solid = @view.lc_button_class(tone: :destructive).split
      assert_includes solid, "[--lc-button-bg:color-mix(in_oklab,var(--destructive)_60%,black)]"
      assert_not_includes solid, "[--lc-button-bg:var(--primary)]"
      assert_nil fragment(@view.lc_button("Save")).at_css("button")["data-tone"]

      assert_equal "destructive", fragment(@view.lc_button_link_to("Sign out", "/session", variant: :outline, tone: :destructive)).at_css("a")["data-tone"]
      assert_includes fragment(@view.lc_button_to("Delete", "/entries/1", method: :delete, variant: :secondary, tone: :destructive)).at_css("button")["class"].split, "text-destructive"
      ButtonHelper::BUTTON_VARIANTS.each_key { |variant| assert @view.lc_button_class(variant: variant, tone: :destructive) }
      assert_raises(ArgumentError) { @view.lc_button("Save", tone: :warning) }
    end

    test "select triggers are buttons with a start-aligned label and a decorative trailing chevron" do
      trigger = fragment(@view.lc_select_trigger("<All members>", size: :sm, block: true, aria: { expanded: false })).at_css("button")
      assert_equal "button", trigger["type"]
      assert_equal "select-trigger", trigger["data-slot"]
      assert_equal "false", trigger["aria-expanded"]
      assert_equal "<All members>", trigger.at_css("span.truncate").text
      chevron = trigger.element_children.last
      assert_equal "inline-end", chevron["data-icon"]
      assert_equal "true", chevron["aria-hidden"]
      classes = trigger["class"].split
      assert_includes classes, "justify-start"
      assert_includes classes, "h-control-sm"
      assert_includes classes, "w-full"

      html = @view.lc_select_trigger { @view.tag.strong("Alex") }
      assert_equal %w[strong svg], fragment(html).at_css("button").element_children.map(&:name)
      assert_raises(ArgumentError) { @view.lc_select_trigger("All", size: :xl) }
    end

    test "split buttons join an action and a menu toggle into one pill for every variant and size" do
      ButtonHelper::BUTTON_VARIANTS.each_key do |variant|
        ButtonHelper::BUTTON_SIZES.each_key do |size|
          html = fragment(@view.lc_split_button("Export", id: "export", variant: variant, size: size) { @view.lc_menu_option("CSV") })
          action = html.at_css("[data-slot=split-button] > button[data-slot=button]")["class"].split
          toggle = html.at_css("[data-slot=split-button-toggle]")["class"].split
          assert_includes action, "rounded-e-none"
          assert_includes action, "border-e-0"
          assert_includes toggle, "rounded-s-none"
          assert_includes toggle, "w-control-#{size}"
          assert_includes toggle, "h-control-#{size}"
          assert_equal variant != :outline, toggle.include?("border-s-[color-mix(in_oklab,currentColor_24%,transparent)]"), variant
          [ action, toggle ].each { |part| assert_not_includes part, "motion-safe:not-disabled:hover:-translate-y-px" }
        end
      end
    end

    test "split buttons wire their toggle to a menu and keep caller hooks on each part" do
      html = fragment(@view.lc_split_button("Add", id: "add", href: "/new", icon: "plus", menu_label: "More ways to add", block: true,
        class: "max-sm:hidden", data: { controller: "import" },
        action: { class: "hook-primary", data: { turbo_frame: "body" }, aria: { expanded: false } },
        toggle: { class: "hook-toggle", data: { action: "click->import#ready" } },
        menu: { class: "hook-menu" }) { @view.lc_menu_option("Import a CSV") })

      wrapper = html.at_css("[data-slot=split-button]")
      assert_equal "lc-menu import", wrapper["data-controller"]
      assert_includes wrapper["class"].split, "w-full"
      assert_includes wrapper["class"].split, "max-sm:hidden"

      action = wrapper.at_css("a")
      assert_equal "/new", action["href"]
      assert_equal "body", action["data-turbo-frame"]
      assert_equal "false", action["aria-expanded"]
      assert_includes action["class"].split, "hook-primary"
      assert_equal "inline-start", action.at_css("svg")["data-icon"]

      toggle = wrapper.at_css("button[data-slot=split-button-toggle]")
      assert_equal "add-trigger", toggle["id"]
      assert_equal "More ways to add", toggle["aria-label"]
      assert_equal "menu", toggle["aria-haspopup"]
      assert_equal "false", toggle["aria-expanded"]
      assert_equal "add", toggle["aria-controls"]
      assert_equal "trigger", toggle["data-lc-menu-target"]
      assert_equal "lc-menu#toggle click->import#ready", toggle["data-action"]
      assert_includes toggle["class"].split, "hook-toggle"
      assert_equal "true", toggle.at_css("svg")["aria-hidden"]

      menu = wrapper.at_css("#add")
      assert_equal "menu", menu["role"]
      assert_equal "add-trigger", menu["aria-labelledby"]
      assert_equal "popover", menu["data-lc-menu-target"]
      assert_includes menu["class"].split, "hook-menu"
      assert_equal "Import a CSV", menu.at_css("[role=menuitem]").text.strip

      assert_equal "button", fragment(@view.lc_split_button("Add", id: "b") { "" }).at_css("[data-slot=button]").name
      assert_raises(ArgumentError) { @view.lc_split_button("Add", id: "") { "" } }
      assert_raises(ArgumentError) { @view.lc_split_button("Add", id: "c", menu_label: " ") { "" } }
      assert_raises(ArgumentError) { @view.lc_split_button("Add", id: "d", variant: :link) { "" } }
      assert_raises(ArgumentError) { @view.lc_split_button("Add", id: "e", size: :xl) { "" } }
    end

    test "badges and eyebrows support escaped text and captured content" do
      [ :lc_badge ].each do |name|
        assert_equal "<new>", fragment(@view.public_send(name, "<new>")).at_css("span").text
        html = @view.public_send(name, id: "label") { @view.tag.strong("New") }
        assert_equal "New", fragment(html).at_css("span#label strong").text
      end
      [ :lc_icon_badge ].each do |name|
        assert_equal "true", fragment(@view.public_send(name, icon: "check")).at_css("svg")["aria-hidden"]
      end
    end

    test "avatars render text or native images with meaningful alt text" do
      assert_equal "<AB>", fragment(@view.lc_avatar("<AB>")).at_css("span").text
      html = @view.lc_avatar { @view.tag.abbr("AB", title: "Ada Baker") }
      assert_equal "Ada Baker", fragment(html).at_css("span abbr")["title"]
      image = fragment(@view.lc_avatar(src: "/avatar.jpg", alt: "Ada", size: :lg, loading: "lazy")).at_css("img")
      assert_equal "/avatar.jpg", image["src"]
      assert_equal "Ada", image["alt"]
      assert_equal "lazy", image["loading"]
      assert_equal "", fragment(@view.lc_avatar(src: "/avatar.jpg")).at_css("img")["alt"]

      html = @view.lc_avatar_stack(compact: true, id: "team") { @view.lc_avatar("AB") }
      assert_equal "AB", fragment(html).at_css("#team .lc-avatar-stack__row > .lc-avatar").text

      button = fragment(@view.lc_avatar("AB", as: :button, aria: { label: "Change colour" })).at_css("button[type=button]")
      assert_includes button["class"].split, "lc-avatar"
      assert_equal "Change colour", button["aria-label"]
      assert_raises(ArgumentError) { @view.lc_avatar("AB", as: :a) }

      row = fragment(@view.lc_avatar_stack(row: { aria: { hidden: true }, data: { stack_target: "row" } }) { @view.lc_avatar("AB") }).at_css(".lc-avatar-stack__row")
      assert_equal "true", row["aria-hidden"]
      assert_equal "row", row["data-stack-target"]
    end

    test "surfaces capture content with merged attributes" do
      [ :lc_card, :lc_empty_state ].each do |name|
        html = @view.public_send(name, id: "content", class: "p-8", data: { controller: "example" }) { @view.tag.h2("Title") }
        surface = fragment(html).at_css("div#content")
        assert_equal "Title", surface.at_css("h2").text
        assert_includes surface["class"].split, "p-8"
        assert_equal "example", surface["data-controller"]
      end
    end

    test "linked cards use native anchors with captured and escaped content" do
      html = @view.lc_card(href: '/guide?query="cards"&sort=new', target: "_blank", rel: "noopener", data: { turbo_frame: "_top" }) { @view.tag.h2("<Guide>") }
      card = fragment(html).at_css("a")
      assert_equal '/guide?query="cards"&sort=new', card["href"]
      assert_equal "_blank", card["target"]
      assert_equal "noopener", card["rel"]
      assert_equal "_top", card["data-turbo-frame"]
      assert_equal "<Guide>", card.at_css("h2").text
      assert_nil card.at_css("guide")
      assert_nil card["role"]
      assert_includes card["class"].split, "flex"
      assert_includes card["class"].split, "hover:bg-accent"

      plain_card = fragment(@view.lc_card(interactive: true) { "Details" }).at_css("div")
      assert_nil plain_card["href"]
      assert_nil plain_card["role"]
      assert_nil plain_card["tabindex"]
    end

    test "loading feedback is announced once or explicitly decorative" do
      spinner = fragment(@view.lc_spinner(label: "Saving")).at_css("span")
      assert_equal "status", spinner["role"]
      assert_equal "Saving", spinner.at_css(".sr-only").text
      assert_nil spinner["aria-hidden"]

      decorative = fragment(@view.lc_spinner(label: nil)).at_css("span")
      assert_nil decorative["role"]
      assert_equal "true", decorative["aria-hidden"]
      assert_equal "", decorative.text

      skeleton = fragment(@view.lc_skeleton(class: "h-8 w-40")).at_css("span")
      assert_equal "true", skeleton["aria-hidden"]
      assert_includes skeleton["class"].split, "h-8"
      assert_not_includes skeleton["class"].split, "h-4"
    end

    test "form alerts escape messages and preserve tone and caller data" do
      alert = fragment(@view.lc_alert("<Error>", data: { controller: "dismiss" }, aria: { describedby: "hint" })).at_css("div")
      assert_equal "alert", alert["role"]
      assert_equal "destructive", alert["data-tone"]
      assert_equal "dismiss", alert["data-controller"]
      assert_equal "hint", alert["aria-describedby"]
      assert_equal "<Error>", alert.at_css("p").text
      assert_nil alert.at_css("error")
      assert_equal "true", alert.at_css("svg")["aria-hidden"]
      assert_equal "status", fragment(@view.lc_alert("Saved", tone: :success)).at_css("div")["role"]
    end

    private
      def fragment(html)
        Nokogiri::HTML.fragment(html)
      end
  end
end
