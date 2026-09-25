require "test_helper"

class HostLayoutLinksTest < ActionDispatch::IntegrationTest
  test "the flow list renders inside a host layout that links with the app's own route helpers" do
    get branded_flows.manage_flows_path

    assert_select "nav a[href=?]", "/home"
  end

  test "a flow's visitor page renders inside a host layout that links with the app's own route helpers" do
    EasyFlow::Definition.create!(host: "branded", slug: "fee").tap do |flow|
      flow.record_definition(flowing("slug" => "fee", "entry" => nil, "nodes" => [], "edges" => []))
      flow.publish
    end

    get branded_flows.flow_path("fee")

    assert_select "nav a[href=?]", "/home"
  end
end
