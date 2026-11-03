require "test_helper"
require "lostcoords/ui/builders"
require "lostcoords/ui/components"

class HomeTest < ActionDispatch::IntegrationTest
  test "the home renders components through the host's helpers" do
    get root_path

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(ApplicationController.helpers.button_class(variant: :accent))
  end

  test "each component page renders its examples and public API" do
    Showcase.sections.each do |section|
      get component_path(component: section.id, format: :html)

      assert_response :success
      assert_includes response.body, "API reference"
      section.builders.each do |name|
        next if name == :render

        assert_includes response.body, ERB::Util.html_escape(name.to_s), "#{name} is missing from #{section.id}"
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
