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
  end
end
