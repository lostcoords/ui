require "test_helper"
require "lostcoords/ui/builders"

class HomeTest < ActionDispatch::IntegrationTest
  test "the dummy app renders a gem builder through the host's helpers" do
    get root_path

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(ApplicationController.helpers.button_class(variant: :accent))
  end

  test "the showcase names every builder the engine gives host views" do
    get root_path

    assert_response :success
    Lostcoords::Ui::Builders.all.each do |builder|
      assert_includes response.body, ERB::Util.html_escape(builder.name.to_s), "#{builder.name} is missing from the showcase"
    end
  end

  test "the emoji picker's catalog renders for the showcase page" do
    get "/emoji-catalog.html"

    assert_response :success
    assert_includes response.body, %(data-emoji="🥝")
  end
end
