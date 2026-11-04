require "test_helper"

module EasyFlow
  class InputsTest < ActiveSupport::TestCase
    def taking(*inputs)
      Node.new(id: "lookup", type: "read_data", config: { "inputs" => inputs })
    end

    test "reads an input with a fixed value as that value" do
      assert_equal({ "sku" => "A1" }, Inputs.values_of(taking({ "name" => "sku", "value" => "A1" }), {}))
    end

    test "reads an input from an earlier step as that step's output" do
      input = { "name" => "sku", "step" => "pick", "output" => "code" }

      assert_equal({ "sku" => "A1" }, Inputs.values_of(taking(input), { "pick" => { "code" => "A1" } }))
    end
  end
end
