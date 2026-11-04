require "test_helper"

module EasyFlow
  class InputsTest < ActiveSupport::TestCase
    def taking(*inputs)
      Node.new(id: "lookup", type: "read_data", config: { "inputs" => inputs })
    end

    test "reads an input with a fixed value as that value" do
      assert_equal({ "sku" => "A1" }, Inputs.values_of(taking({ "name" => "sku", "value" => "A1" }), {}))
    end
  end
end
