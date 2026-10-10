require "test_helper"

module EasyFlow
  class CountTest < ActiveSupport::TestCase
    def count(config)
      Node.new(id: "tries", type: "count", config: config)
    end

    test "records how many times the earlier step has been visited when no answer is picked" do
      node = count({ "step" => "tests" })

      assert_equal 3, Count.step_type.process(node, { "tests" => "failed", "tests@2" => "failed", "tests@3" => "passed" })
    end
  end
end
