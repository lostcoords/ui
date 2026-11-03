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

    test "public button variants and sizes are strict and accept strings" do
      html = @view.lc_button("Remove", variant: "destructive", size: "sm")
      assert_includes fragment(html).at_css("button")["class"].split, "text-berry"

      { variant: :accent, size: :nav }.each do |name, value|
        error = assert_raises(ArgumentError) { @view.lc_button("Save", **{ name => value }) }
        assert_includes error.message, name.to_s
      end
      assert_raises(ArgumentError) { @view.lc_badge("New", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_medallion(icon: "check", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_icon_badge(icon: "check", size: :missing) }
      assert_raises(ArgumentError) { @view.lc_avatar("AB", size: nil) }
      assert_raises(ArgumentError) { @view.lc_form_card(padding: :missing) }
      assert_raises(ArgumentError) { @view.lc_status_pill("New", tone: :missing) }
      assert_raises(ArgumentError) { @view.lc_spinner(size: :missing) }
      assert_raises(ArgumentError) { @view.lc_form_alert("Oops", tone: :missing) }
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

    test "badges and eyebrows support escaped text and captured content" do
      [ :lc_badge, :lc_status_pill, :lc_eyebrow ].each do |name|
        assert_equal "<new>", fragment(@view.public_send(name, "<new>")).at_css("span").text
        html = @view.public_send(name, id: "label") { @view.tag.strong("New") }
        assert_equal "New", fragment(html).at_css("span#label strong").text
      end
      [ :lc_icon_badge, :lc_medallion ].each do |name|
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
      assert_equal "AB", fragment(html).at_css("#team .avatar-stack__row > .avatar").text
    end

    test "surfaces capture content with merged attributes" do
      [ :lc_card, :lc_card_surface, :lc_form_card, :lc_empty_state ].each do |name|
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
      assert_includes card["class"].split, "block"
      assert_includes card["class"].split, "hover:bg-paper-3"

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
      alert = fragment(@view.lc_form_alert("<Error>", data: { controller: "dismiss" }, aria: { describedby: "hint" })).at_css("div")
      assert_equal "alert", alert["role"]
      assert_equal "error", alert["data-tone"]
      assert_equal "dismiss", alert["data-controller"]
      assert_equal "hint", alert["aria-describedby"]
      assert_equal "<Error>", alert.at_css("p").text
      assert_nil alert.at_css("error")
      assert_equal "true", alert.at_css("svg")["aria-hidden"]
      assert_equal "status", fragment(@view.lc_form_alert("Saved", tone: :notice)).at_css("div")["role"]
    end

    private
      def fragment(html)
        Nokogiri::HTML.fragment(html)
      end
  end
end
