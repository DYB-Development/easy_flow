require "test_helper"

module EasyFlow
  class AdminAuthenticationTest < ActionDispatch::IntegrationTest
    test "the pages that manage flows run the host's admin check first" do
      EasyFlow.host_named(:dummy).admin_authentication_method = :turn_away_the_admin

      get easy_flow.manage_flows_path

      assert_response :forbidden
    ensure
      EasyFlow.host_named(:dummy).admin_authentication_method = nil
    end

    test "a host's pages that manage flows run the admin check that host names" do
      EasyFlow.host_named(:console).admin_authentication_method = :turn_away_the_admin

      get console_flows.manage_flows_path

      assert_response :forbidden
    ensure
      EasyFlow.host_named(:console).admin_authentication_method = nil
    end
  end
end
