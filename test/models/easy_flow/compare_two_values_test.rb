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

    test "decides false when a side has not been answered yet" do
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
  end
end
