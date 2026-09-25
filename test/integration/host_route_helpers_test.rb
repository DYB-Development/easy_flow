require "test_helper"

class HostRouteHelpersTest < ActionDispatch::IntegrationTest
  test "the flow list links each flow on its own page when the host app gives every view its own route helpers" do
    flow = EasyFlow::Definition.create!(host: "dummy", slug: "fee")

    get easy_flow.manage_flows_path

    assert_select "a[href=?]", easy_flow.manage_flow_path(flow)
  end
end
