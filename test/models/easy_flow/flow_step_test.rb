require "test_helper"

module EasyFlow
  class FlowStepTest < ActiveSupport::TestCase
    test "is registered for a flow to use, named Flow" do
      assert_equal "Flow", EasyFlow.registry.fetch("flow_step").step_name
    end

    test "takes the number of the version it runs" do
      assert_equal :integer, FlowStep.step_type.settings.fields[:version]
    end
  end
end
