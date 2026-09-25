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
  end
end
