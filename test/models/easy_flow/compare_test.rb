require "test_helper"

module EasyFlow
  class CompareTest < ActiveSupport::TestCase
    def compare(config)
      Node.new(id: "check", type: "compare", config: config)
    end

    test "decides true when the step's number is more than the amount" do
      node = compare({ "step" => "surplus", "comparison" => "more than", "amount" => 2000 })

      assert_equal true, Compare.step_type.route(node, { "surplus" => 2500 })
    end

    test "decides true when the step's number is less than the amount" do
      node = compare({ "step" => "balance", "comparison" => "less than", "amount" => 5000 })

      assert_equal true, Compare.step_type.route(node, { "balance" => 4000 })
    end

    test "decides true when the step's number is at least the amount" do
      node = compare({ "step" => "surplus", "comparison" => "at least", "amount" => 2000 })

      assert_equal true, Compare.step_type.route(node, { "surplus" => 2000 })
    end

    test "decides true when the step's number is at most the amount" do
      node = compare({ "step" => "balance", "comparison" => "at most", "amount" => 5000 })

      assert_equal true, Compare.step_type.route(node, { "balance" => 5000 })
    end

    test "decides false when the step has not been answered yet" do
      node = compare({ "step" => "surplus", "comparison" => "more than", "amount" => 2000 })

      assert_equal false, Compare.step_type.route(node, {})
    end

    test "compares the output it names when the step recorded several" do
      node = compare({ "step" => "rainy_day", "output" => "amount", "comparison" => "less than", "amount" => 500 })

      assert_equal true, Compare.step_type.route(node, { "rainy_day" => { "account" => "Savings", "amount" => 200 } })
    end
  end
end
