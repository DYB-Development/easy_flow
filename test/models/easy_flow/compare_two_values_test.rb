require "test_helper"

module EasyFlow
  class CompareTwoValuesTest < ActiveSupport::TestCase
    def compare(config)
      Node.new(id: "check", type: "compare_two_values", config: config)
    end

    test "decides true when the first step's number is more than the second step's" do
      node = compare({ "step" => "spent", "comparison" => "more than", "other_step" => "budget" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 120, "budget" => 100 })
    end

    test "decides true when the first step's number is less than the second step's" do
      node = compare({ "step" => "spent", "comparison" => "less than", "other_step" => "budget" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 80, "budget" => 100 })
    end

    test "decides true when the first step's number is at least the second step's" do
      node = compare({ "step" => "spent", "comparison" => "at least", "other_step" => "budget" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 100, "budget" => 100 })
    end

    test "decides true when the first step's number is at most the second step's" do
      node = compare({ "step" => "spent", "comparison" => "at most", "other_step" => "budget" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 100, "budget" => 100 })
    end

    test "decides true when the first step's number is equal to the second step's" do
      node = compare({ "step" => "spent", "comparison" => "equal to", "other_step" => "budget" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 100, "budget" => 100 })
    end

    test "compares the first number with the second number plus the amount drawn" do
      node = compare({ "step" => "spent", "comparison" => "more than", "other_step" => "budget", "amount" => 50 })

      assert_equal false, CompareTwoValues.step_type.route(node, { "spent" => 120, "budget" => 100 })
    end

    test "treats an amount left empty as zero" do
      node = compare({ "step" => "spent", "comparison" => "at least", "other_step" => "budget", "amount" => "" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "spent" => 100, "budget" => 100 })
    end

    test "decides false when a side has no value recorded yet" do
      node = compare({ "step" => "spent", "comparison" => "less than", "other_step" => "budget" })

      assert_equal false, CompareTwoValues.step_type.route(node, { "budget" => 100 })
    end

    test "decides false when a side's answer is not a number" do
      node = compare({ "step" => "spent", "comparison" => "less than", "other_step" => "budget" })

      assert_equal false, CompareTwoValues.step_type.route(node, { "spent" => "plenty", "budget" => 100 })
    end

    test "reads the first side from the output it names when that step recorded several" do
      node = compare({ "step" => "tests", "output" => "took", "comparison" => "more than", "other_step" => "limit" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "tests" => { "result" => "passed", "took" => 90 }, "limit" => 60 })
    end

    test "reads the second side from the output it names when that step recorded several" do
      node = compare({ "step" => "took", "comparison" => "more than", "other_step" => "last_run", "other_output" => "took" })

      assert_equal true, CompareTwoValues.step_type.route(node, { "took" => 90, "last_run" => { "result" => "passed", "took" => 60 } })
    end

    test "asks for an earlier step on each side, a comparison and an amount" do
      fields = CompareTwoValues.step_type.settings.fields

      assert_equal({ step: :previous_step, comparison: :select, other_step: :previous_step, amount: :float }, fields.slice(:step, :comparison, :other_step, :amount))
    end

    test "offers each side's step outputs to pick from" do
      assert_equal({ output: :step, other_output: :other_step }, CompareTwoValues.step_type.settings.outputs_of)
    end

    test "declares the true or false result it decides as an output" do
      assert_equal [ true, false ], CompareTwoValues.step_type.values_of(:result, compare({})).map { |value| value["value"] }
    end

    test "is offered to every host's flows" do
      assert EasyFlow.registry.registered?(:compare_two_values)
    end

    test "a flow follows the route Compare two values decides from two answers" do
      registry = Registry.new.tap do |built|
        [ Start, Terminal, CompareTwoValues ].each { |step| step.register(built) }
        built.register(StepType.define(:ask) { awaits_input })
      end
      flow = { "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "spent", "type" => "ask" }, { "id" => "budget", "type" => "ask" },
                            { "id" => "over", "type" => "compare_two_values", "step" => "spent", "comparison" => "more than", "other_step" => "budget" },
                            { "id" => "warn", "type" => "terminal", "output" => "over budget" }, { "id" => "fine", "type" => "terminal", "output" => "within budget" } ],
               "edges" => [ { "from" => "start", "to" => "spent" }, { "from" => "spent", "to" => "budget" }, { "from" => "budget", "to" => "over" },
                            { "from" => "over", "to" => "warn", "on" => "true" }, { "from" => "over", "to" => "fine", "on" => "false" } ] }

      assert_equal "within budget", Digest.new(Document.new(flow, registry: registry), registry: registry).output({ "spent" => "80", "budget" => "100" })
    end

    test "compares the minutes two steps completed at, so it can route on the time between them" do
      node = compare({ "step" => "finished", "output" => "completed_minute", "comparison" => "more than", "other_step" => "started", "other_output" => "completed_minute", "amount" => 30 })
      times = { "started" => Time.zone.local(2026, 10, 12, 9, 0), "finished" => Time.zone.local(2026, 10, 12, 9, 45) }

      assert_equal true, CompareTwoValues.step_type.route(node, { "started" => "passed", "finished" => "passed" }, times)
    end
  end
end
