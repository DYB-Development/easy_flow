require "test_helper"

module EasyFlow
  class StepTest < ActiveSupport::TestCase
    class Probe
      include Step

      step_name "Probe step"
    end

    class Gate
      include Step

      def route(node, state)
        state[node.config["answer"]].present? ? :yes : :no
      end
    end

    test "derives its id from the class name" do
      assert_equal :probe, Probe.step_type.id
    end

    test "carries a declaration made at class level" do
      assert_equal "Probe step", Probe.step_type.step_name
    end

    test "registers itself without defining a register method" do
      registry = Registry.new

      Probe.register(registry)

      assert registry.registered?(:probe)
    end

    test "routes with a method on the class" do
      node = Node.new(id: "g", type: "gate", config: { "answer" => "a" })

      assert_equal :yes, Gate.step_type.route(node, { "a" => "picked" })
    end
  end
end
