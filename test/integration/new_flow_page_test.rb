require "test_helper"

module EasyFlow
  class NewFlowPageTest < ActionDispatch::IntegrationTest
    test "the new flow page shows the form that creates a flow" do
      get easy_flow.new_manage_flow_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end

    test "the new flow page asks for a kind when the host has set none" do
      get easy_flow.new_manage_flow_path

      assert_select "select[name=?]", "flow[kind]"
    end

    test "a flow created from the page has the kind chosen when the host has set none" do
      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "scored" } }

      assert_equal "scored", Definition.find_by!(host: "dummy", title: "Morning Routine").kind
    end

    test "the new flow page asks for a slug when the host has not set slugs from titles" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[slug]"
    end

    test "the new flow page does not ask for a title when the host has not set slugs from titles" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[title]", count: 0
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
      post easy_flow.manage_flows_path, params: { flow: { title: "", kind: "guide" } }

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end
  end
end
