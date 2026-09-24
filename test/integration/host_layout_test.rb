require "test_helper"

module EasyFlow
  class HostLayoutTest < ActionDispatch::IntegrationTest
    test "a flow renders inside the host application layout" do
      get easy_flow.flow_path(easy_flow_definitions(:db_guide).slug)

      assert_select "meta[name=application-name][content=Dummy]"
    end

    test "the host layout takes keystone's light theme when nothing else is chosen" do
      get easy_flow.manage_flows_path

      assert_select "html[data-theme=light]"
    end
  end
end
