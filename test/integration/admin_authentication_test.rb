require "test_helper"

module EasyFlow
  class AdminAuthenticationTest < ActionDispatch::IntegrationTest
    test "the pages that manage flows run the host's admin check first" do
      EasyFlow.admin_authentication_method = :turn_away_the_admin

      get easy_flow.manage_flows_path

      assert_response :forbidden
    ensure
      EasyFlow.admin_authentication_method = nil
    end
  end
end
