require "test_helper"
require "lostcoords/ui/builders"

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

  test "a component that does not exist returns not found" do
    get component_path(component: "missing", format: :html)

    assert_response :not_found
  end

  test "the emoji catalog renders for the picker" do
    get "/emoji-catalog.html"

    assert_response :success
    assert_includes response.body, %(data-emoji="🥝")
  end
end
