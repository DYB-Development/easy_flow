require "test_helper"

module EasyFlow
  class RegistryTest < ActiveSupport::TestCase
    test "declaring a step type puts it in the default registry" do
      EasyFlow.step(:probe) { step_name "Probe" }

      assert_equal "Probe", EasyFlow.registry.fetch("probe").step_name
    end

    test "knows whether a step type is registered" do
      registry = Registry.new
      registry.register(StepType.define(:question) { })

      assert registry.registered?("question")
    end

    test "does not claim a step type it was never given" do
      assert_not Registry.new.registered?("question")
    end

    test "does not claim a step type for a node carrying no type at all" do
      assert_not Registry.new.registered?(nil)
    end

    test "starts with no step types registered" do
      assert_empty Registry.new.step_types
    end

    test "finds a step type by the identifier a document uses" do
      registry = Registry.new
      registry.register(StepType.define(:question) { })

      assert_equal :question, registry.fetch("question").id
    end

    test "fails clearly for a step type that was never registered" do
      assert_raises UnknownStepType do
        Registry.new.fetch("question")
      end
    end
  end
end
