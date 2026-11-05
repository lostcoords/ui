require "test_helper"
require "lostcoords/ui/builders"
require "lostcoords/ui/components"

class HomeTest < ActionDispatch::IntegrationTest
  test "the home renders components through the host's helpers" do
    get root_path

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(ApplicationController.helpers.lc_button_class(variant: :primary))
  end

  test "every component helper is documented on exactly one page" do
    owned = Showcase.sections.flat_map(&:components)

    assert_equal Lostcoords::Ui::Components.all.map(&:name).sort, owned.sort
  end

  test "each component page documents only its own helpers and links the rest" do
    Showcase.sections.each do |section|
      get component_path(component: section.id, format: :html)

      assert_response :success
      assert_includes response.body, "API reference"
      section.components.each do |name|
        assert_select "##{name}", { count: 1 }, "#{name} is missing from #{section.id}"
      end
      section.related.each do |name|
        assert_select "##{name}", { count: 0 }, "#{section.id} documents #{name}, which another page owns"
        assert_select %(#api a[href="/components/#{Showcase.owner(name).id}.html##{name}"]), { count: 1 }, "#{section.id} does not link #{name}"
      end
    end
  end

  test "compound helpers document the parts they yield" do
    get component_path(component: :card, format: :html)

    %w[header title description content footer].each { |part| assert_select "#card-#{part}", text: "card.#{part}" }
  end

  test "the components index lists every component alphabetically and shares navigation order" do
    get "/components.html"

    assert_response :success
    assert_select "h1", text: "Components"
    components = Showcase.sections.reject { |section| section.id == :foundations }.sort_by(&:title)
    assert_select 'main ul[aria-label="All components"] a' do |links|
      assert_equal components.map { |component| "/components/#{component.id}.html" }, links.map { |link| link["href"] }
    end
    assert_select 'header nav a[href="/components.html"][aria-current="page"]', count: 1

    header_links = css_select('header nav[aria-label="Main"] a').map { |link| link["href"] }
    assert_select 'nav[aria-label="Documentation"] ul[aria-label="Library"]' do |sidebars|
      assert_equal 2, sidebars.size
      sidebars.each do |sidebar|
        assert_equal header_links, sidebar.css("a").map { |link| link["href"] }
      end
    end
  end

  test "machine references expose the real public API with runnable examples" do
    get "/api.json"

    assert_response :success
    reference = JSON.parse(response.body)
    assert_equal "Rails", reference.fetch("adapter")
    assert_equal Lostcoords::Ui::Components.all.map { |component| component.name.to_s }, reference.fetch("components").map { |component| component.fetch("name") }
    reference.fetch("components").each do |component|
      assert component.fetch("examples").any?, "#{component.fetch('name')} has no example"
      component.fetch("examples").each do |example|
        assert_includes example.fetch("erb"), component.fetch("name")
        refute_includes example.fetch("erb"), "EXAMPLE_ID"
      end
    end
    assert_equal Lostcoords::Ui::TOKENS.map(&:to_s), reference.fetch("tokens").map(&:to_s)

    get "/llms.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    Lostcoords::Ui::Components.all.each { |component| assert_includes response.body, component.signature }
  end

  test "installation provides a complete starter stylesheet and explains Rails loading" do
    get "/installation.html"

    assert_response :success
    assert_includes response.body, "Gemfile.lock"
    assert_includes response.body, "javascript_importmap_tags"

    get "/starter.css"

    assert_response :success
    assert_equal "text/css", response.media_type
    refute_includes response.body, ":root"
    assert_includes response.body, '@import "../builds/tailwind/lostcoords_ui.css"'
    refute_includes response.body, "--palette-"
    refute_includes response.body, "--syntax-"
  end

  test "the old tokens URL serves the theming guide" do
    get "/theming.html"

    assert_response :success
    guide = response.body

    get "/tokens.html"

    assert_response :success
    assert_equal guide, response.body
  end

  test "theme colors and other style settings stay visible in separate groups" do
    get "/components/foundations.html"

    assert_response :success
    assert_select "#theme-color-table tbody tr", count: 20
    assert_select "#theme-color-table [data-token='--primary']", text: /Primary actions, links, selected states and keyboard focus/
    assert_select "section#style-settings #foundation-token-table"
    assert_select "details #foundation-token-table", count: 0
    refute_includes response.body, "Tailwind utility alias"
    refute_includes response.body, "Palette and status colors"
    refute_includes response.body, "--color-primary"
  end

  test "a component that does not exist returns not found" do
    get component_path(component: "missing", format: :html)

    assert_response :not_found
  end

  test "the emoji catalog renders for the picker" do
    get "/emoji-catalog.html"

    assert_response :success
    assert_includes response.body, %(data-emoji="🥝")
  end
  test "the palette attribution is available in the live preview" do
    get "/wada-license.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "Copyright (c) 2020 Matt DesLauriers"
  end
end
