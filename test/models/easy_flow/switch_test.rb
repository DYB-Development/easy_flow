require "test_helper"

module EasyFlow
  class SwitchTest < ActiveSupport::TestCase
    def switch(config)
      Node.new(id: "fork", type: "switch", config: config)
    end

    test "declares the step it directs on" do
      assert_equal :previous_step, Switch.step_type.settings.fields[:step]
    end

    test "directs on the values the step it names outputs" do
      assert_equal :step, Switch.step_type.outputs.first.from
    end

    test "directs by the answer the step it names gave" do
      assert_equal "high", Switch.step_type.route(switch({ "step" => "budget" }), { "budget" => "high" })
    end

    test "requires the step it directs on" do
      assert_equal [ "budget" ], Switch.step_type.settings.requirements_for(switch({ "step" => "budget" }).config)
    end

    test "registers through the public step-type API" do
      registry = Registry.new

      Switch.register(registry)

      assert_equal :switch, registry.fetch("switch").id
    end

    test "is registered for the application to use" do
      assert_equal :switch, EasyFlow.registry.fetch("switch").id
    end

    test "cannot run without the step it directs on" do
      assert_equal [ :step ], Switch.step_type.settings.required
    end
  end
end
