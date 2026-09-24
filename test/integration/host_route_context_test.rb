require "test_helper"

module EasyFlow
  class HostRouteContextTest < ActionDispatch::IntegrationTest
    test "engine controllers inherit the host's application controller" do
      assert_includes FlowsController.ancestors, ::ApplicationController
    end
  end
end
