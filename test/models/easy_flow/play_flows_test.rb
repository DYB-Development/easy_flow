require "test_helper"

module EasyFlow
  class PlayFlowsTest < ActiveSupport::TestCase
    test "is registered for a flow to use, named Play flows" do
      assert_equal "Play flows", EasyFlow.registry.fetch("play_flows").step_name
    end

    test "takes the flows it offers, chosen from the flows the canvas offers" do
      assert_equal :flows, PlayFlows.step_type.settings.fields[:flows]
    end
  end
end
