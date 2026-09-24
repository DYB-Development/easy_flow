require "test_helper"

module EasyFlow
  class ConditionTest < ActiveSupport::TestCase
    def branch(config)
      Node.new(id: "branch", type: "condition", config: config)
    end

    test "requires the step whose answer it tests" do
      node = branch({ "step" => "budget", "answer" => "high" })

      assert_equal [ "budget" ], Condition.step_type.settings.requirements_for(node.config)
    end

    test "requires nothing when it names no step to test" do
      assert_empty Condition.step_type.settings.requirements_for(branch({}).config)
    end

    test "registers through the public step-type API" do
      registry = Registry.new

      Condition.register(registry)

      assert_equal :condition, registry.fetch("condition").id
    end

    test "decides true when the step gave the answer it tests for" do
      node = branch({ "step" => "budget", "answer" => "high" })

      assert_equal true, Condition.step_type.route(node, { "budget" => "high" })
    end

    test "decides false when the step gave a different answer" do
      node = branch({ "step" => "budget", "answer" => "high" })

      assert_equal false, Condition.step_type.route(node, { "budget" => "low" })
    end

    test "decides false when the step has not been answered yet" do
      node = branch({ "step" => "budget", "answer" => "high" })

      assert_equal false, Condition.step_type.route(node, {})
    end

    test "does not await external input" do
      assert_not_predicate Condition.step_type, :awaits_input?
    end

    test "declares the step whose answer it tests as one that comes before it" do
      assert_equal :previous_step, Condition.step_type.settings.fields[:step]
    end

    test "draws the answer it tests from the output it names" do
      assert_equal :output, Condition.step_type.settings.drawn_from[:answer]
    end

    test "declares the result it decides as an output" do
      assert_equal [ :result ], Condition.step_type.outputs.map(&:name)
    end

    test "cannot run without the step, output, comparison and answer it tests" do
      assert_equal [ :step, :output, :comparison, :answer ], Condition.step_type.settings.required
    end

    test "offers a comparison deciding which way the test falls" do
      assert_equal [ "is", "is not" ], Condition.step_type.settings.choices[:comparison]
    end

    test "decides false when the step gave the answer it tests for and is not" do
      node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

      assert_equal false, Condition.step_type.route(node, { "budget" => "high" })
    end

    test "decides true when the step gave a different answer and is not" do
      node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

      assert_equal true, Condition.step_type.route(node, { "budget" => "low" })
    end

    test "names itself by the test it makes" do
      node = branch({ "step" => "budget", "comparison" => "is not", "answer" => "high" })

      assert_equal "budget is not high", Condition.step_type.name_of(node)
    end

    test "names which output of that step it reads" do
      assert_equal :step, Condition.step_type.settings.outputs_of[:output]
    end
  end
end
