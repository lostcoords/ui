require "test_helper"

# The sidebar reads its cookie through a real request, as a host's layout renders it.
class SidebarCookieTest < ActionDispatch::IntegrationTest
  def sidebar = Nokogiri::HTML(response.body).at_css("#example-0 [data-slot=sidebar]")

  test "the server renders the state saved in the sidebar's cookie" do
    get "/components/sidebar"
    assert_response :success
    assert_nil sidebar["data-collapsed"]
    assert_nil sidebar["data-expanded"]
    assert_equal "Collapse sidebar", sidebar.at_css("[data-slot=sidebar-toggle]")["aria-label"]

    cookies["docs_sidebar"] = "collapsed"
    get "/components/sidebar"
    assert_equal "true", sidebar["data-collapsed"]
    toggle = sidebar.at_css("[data-slot=sidebar-toggle]")
    assert_equal "Expand sidebar", toggle["aria-label"]
    assert_equal "false", toggle["aria-expanded"]

    cookies["docs_sidebar"] = "expanded"
    get "/components/sidebar"
    assert_equal "true", sidebar["data-expanded"]
    assert_nil sidebar["data-collapsed"]

    cookies["docs_sidebar"] = "sideways"
    get "/components/sidebar"
    assert_nil sidebar["data-collapsed"]
    assert_nil sidebar["data-expanded"]
  end
end
