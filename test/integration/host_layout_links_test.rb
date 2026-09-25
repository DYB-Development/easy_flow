require "test_helper"

class HostLayoutLinksTest < ActionDispatch::IntegrationTest
  test "the flow list renders inside a host layout that links with the app's own route helpers" do
    get branded_flows.manage_flows_path

    assert_select "nav a[href=?]", "/home"
  end
end
