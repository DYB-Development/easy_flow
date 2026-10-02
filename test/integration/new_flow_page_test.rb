require "test_helper"

module EasyFlow
  class NewFlowPageTest < ActionDispatch::IntegrationTest
    test "the new flow page shows the form that creates a flow" do
      get easy_flow.new_manage_flow_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end
  end
end
