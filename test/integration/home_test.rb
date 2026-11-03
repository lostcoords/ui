require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "the dummy app renders a gem builder through the host's helpers" do
    get root_path

    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(ApplicationController.helpers.button_class(variant: :accent))
  end
end
