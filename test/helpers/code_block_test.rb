require "test_helper"

module Lostcoords::Ui
  class CodeBlockTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    test "plain source is escaped and preserves whitespace even when marked HTML safe" do
      source = "  <script>alert('hello')</script>\n\t<&>\n".html_safe
      html = fragment(@view.lc_code_block(source, id: "example", language: :html, label: "HTML example", class: "w-full", data: { controller: "analytics", action: "click->analytics#track" }))
      assert_equal source, html.at_css("pre code").text
      assert_nil html.at_css("script")
      assert_equal "example", html.at_css("[data-controller]")["id"]
      assert_equal "lc-code-block analytics", html.at_css("[data-controller]")["data-controller"]
      assert_includes html.at_css("[data-controller]")["data-action"], "lc-copy:error->lc-code-block#copyFailed"
      assert_includes html.at_css("[data-controller]")["class"].split, "w-full"
      assert_equal "example-content", html.at_css("[data-lc-copy-source-value]")["data-lc-copy-source-value"]
      assert_equal "HTML example", html.at_css("pre")["aria-label"]
      assert_equal "Copy HTML example", html.at_css("button")["aria-label"]
      assert_empty html.at_css("button").text.strip
      assert_nil html.at_css("[data-lc-code-block-target=toggle]")
    end

    test "callers can supply highlighted markup without changing source text" do
      source = "puts '<hello>'\n"
      html = @view.lc_code_block(source, id: "highlighted") { |code| @view.tag.span(code, class: "token") }
      assert_equal source, fragment(html).at_css("pre code").text
      assert fragment(html).at_css("pre code span.token")
      assert_nil fragment(html).at_css("hello")
    end

    test "headers are optional and filename titles are escaped" do
      plain = fragment(@view.lc_code_block("puts 'hello'", id: "plain", language: :ruby))
      assert_equal "ruby", plain.at_css("code")["data-language"]
      assert_equal "puts 'hello'", plain.text.strip
      titled = fragment(@view.lc_code_block("puts 'hello'", id: "file", title: "<draft>.rb"))
      assert_equal "<draft>.rb", titled.at_css(".lc-code-block > div > span").text
      assert_nil titled.at_css("draft")
      assert_equal plain.at_css("pre code").text, titled.at_css("pre code").text
    end

    test "long snippets expose collapse controls and can opt out" do
      source = (1..12).map { |n| "line #{n}\n" }.join
      html = fragment(@view.lc_code_block(source, id: "long", max_lines: 5))
      toggle = html.at_css("[data-lc-code-block-target=toggle]")
      assert_equal source, html.at_css("pre code").text
      assert_equal "--lc-code-block-lines: 5", html.at_css("pre")["style"]
      assert_equal "false", toggle["aria-expanded"]
      assert_equal html.at_css("pre")["id"], toggle["aria-controls"]
      assert_equal "Show all code", toggle.text
      assert_equal "Show less code", toggle["data-collapse-label"]
      full = fragment(@view.lc_code_block(source, id: "full", max_lines: nil))
      assert_nil full.at_css("[data-lc-code-block-target=toggle]")
      refute_includes full.at_css("pre")["class"], "max-h-"
    end

    test "labels and collapse controls follow the view locale" do
      { ja: [ "ソースコードをコピー", "コードをすべて表示" ], es: [ "Copiar Código fuente", "Mostrar todo el código" ] }.each do |locale, (copy, expand)|
        I18n.with_locale(locale) do
          html = fragment(@view.lc_code_block("one\ntwo", id: "localized", max_lines: 1))
          assert_equal copy, html.at_css("button")["aria-label"]
          assert_equal expand, html.at_css("[data-lc-code-block-target=toggle]").text
        end
      end
    end

    test "invalid labels and collapse limits fail at the component boundary" do
      [ 0, -1, 1.5, "10", false ].each do |max_lines|
        assert_raises(ArgumentError) { @view.lc_code_block("code", id: "example", max_lines: max_lines) }
      end
      assert_raises(ArgumentError) { @view.lc_code_block("code", id: "") }
      assert_raises(ArgumentError) { @view.lc_code_block("code", id: "example", label: "") }
      assert_raises(ArgumentError) { @view.lc_code_block("code", id: "example", title: "") }
    end

    private
      def fragment(html) = Nokogiri::HTML.fragment(html)
  end
end
