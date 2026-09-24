require "test_helper"

module EasyFlow
  class HostManagementTest < ActionDispatch::IntegrationTest
    test "a host's flow list leaves out another host's flows" do
      Definition.create!(host: "console", slug: "console-setup", title: "Console setup")

      get easy_flow.manage_flows_path

      assert_select "a", text: "Console setup", count: 0
    end

    test "a flow created on a host's management pages belongs to that host" do
      post easy_flow.manage_flows_path, params: { flow: { slug: "made-here", kind: "guide" } }

      assert_equal "dummy", Definition.find_by!(slug: "made-here").host
    end
  end
end
