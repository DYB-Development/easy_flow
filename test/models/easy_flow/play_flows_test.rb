require "test_helper"

module EasyFlow
  class PlayFlowsTest < ActiveSupport::TestCase
    test "is registered for a flow to use, named Play flows" do
      assert_equal "Play flows", EasyFlow.registry.fetch("play_flows").step_name
    end
  end
end
