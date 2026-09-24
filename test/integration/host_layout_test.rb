require "test_helper"

module EasyFlow
  class HostLayoutTest < ActionDispatch::IntegrationTest
    test "a flow renders inside the host application layout" do
      get easy_flow.flow_path(easy_flow_definitions(:db_guide).slug)

      assert_select "meta[name=application-name][content=Dummy]"
    end
  end
end
