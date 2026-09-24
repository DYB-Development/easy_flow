require "test_helper"

module EasyFlow
  class HostManagementTest < ActionDispatch::IntegrationTest
    test "a host's flow list leaves out another host's flows" do
      Definition.create!(host: "console", slug: "console-setup", title: "Console setup")

      get easy_flow.manage_flows_path

      assert_select "a", text: "Console setup", count: 0
    end
  end
end
