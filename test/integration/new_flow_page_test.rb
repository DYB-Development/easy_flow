require "test_helper"

module EasyFlow
  class NewFlowPageTest < ActionDispatch::IntegrationTest
    test "the new flow page shows the form that creates a flow" do
      get easy_flow.new_manage_flow_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end

    test "the flow list links to the new flow page" do
      get easy_flow.manage_flows_path

      assert_select "a[href=?]", easy_flow.new_manage_flow_path
    end

    test "the flow list has no form that creates a flow" do
      get easy_flow.manage_flows_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path, count: 0
    end

    test "a flow that cannot be created is shown again on the new flow page" do
      post easy_flow.manage_flows_path, params: { flow: { slug: "", kind: "guide" } }

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end
  end
end
