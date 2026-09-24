require "test_helper"

module EasyFlow
  class RetiredHostTest < ActionDispatch::IntegrationTest
    test "the management pages of a host no longer set up are not found" do
      get retired_flows.manage_flows_path

      assert_response :not_found
    end
  end
end
