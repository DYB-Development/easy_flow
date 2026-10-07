require "test_helper"

module EasyFlow
  class FlowStepTest < ActiveSupport::TestCase
    test "is registered for a flow to use, named Flow" do
      assert_equal "Flow", EasyFlow.registry.fetch("flow_step").step_name
    end
  end
end
