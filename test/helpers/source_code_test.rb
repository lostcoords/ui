require "test_helper"

class SourceCodeTest < ActiveSupport::TestCase
  test "highlighting preserves the exact ERB source including Unicode" do
    source = %(<%= ui_button "保存 & <script>", icon: "plus" %>\n<p class="text-sm">日本語</p>)
    html = ApplicationController.helpers.highlight_source(source)
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal source, fragment.text
    assert_empty fragment.css("script, p")
    assert fragment.at_css('[data-syntax="string"]')
    assert fragment.at_css('[data-syntax="call"]')
    assert fragment.at_css('[data-syntax="tag"]')
  end

  test "every runnable specimen survives highlighting without changing copied code" do
    Showcase.sections.flat_map(&:examples).each do |example|
      html = ApplicationController.helpers.highlight_source(example.source)
      assert_equal example.source, Nokogiri::HTML.fragment(html).text, example.specimen.to_s
    end
  end

  test "JavaScript and CSS preserve comments strings and Unicode" do
    samples = {
      javascript: 'const label = "保存 // label"; /* note */ button.focus()',
      css: '.button { --accent: #315b9a; content: "保存"; /* note */ color: var(--accent); }'
    }
    samples.each do |language, source|
      html = ApplicationController.helpers.highlight_source(source, language: language)
      fragment = Nokogiri::HTML.fragment(html)
      assert_equal source, fragment.text
      assert fragment.at_css('[data-syntax="string"]')
      assert fragment.at_css('[data-syntax="comment"]')
    end
  end

  test "Ruby fragments and ERB comments remain readable and escaped" do
    source = "gem \"lostcoords-ui\", github: \"lostcoords/ui\"\n"
    assert_equal source, Nokogiri::HTML.fragment(ApplicationController.helpers.highlight_source(source, language: :ruby)).text
    comment = "<%# <script>alert(1)</script> %>"
    html = ApplicationController.helpers.highlight_source(comment)
    assert_equal comment, Nokogiri::HTML.fragment(html).text
    assert_empty Nokogiri::HTML.fragment(html).css("script")
  end
end
