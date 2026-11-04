require "test_helper"

module EasyFlow
  class DataStepTest < ActiveSupport::TestCase
    class Shelf
      def reads = %w[stock]
      def writes = %w[restock]

      def carry_out(name, values)
        { "name" => name, "sku" => values["sku"] }
      end
    end

    setup { EasyFlow.data_source = Shelf.new }
    teardown { EasyFlow.data_source = nil }

    def read(config)
      Node.new(id: "lookup", type: "read_data", config: config)
    end

    test "records what the app answers to a read given the input values" do
      node = read({ "data" => "stock", "inputs" => [ { "name" => "sku", "value" => "A1" } ] })

      recorded = ReadData.step_type.process(node, {})

      assert_equal [ "stock", "A1" ], recorded.values_at("name", "sku")
    end

    test "records what the app answers to a write given the input values" do
      node = Node.new(id: "add", type: "write_data", config: { "data" => "restock", "inputs" => [ { "name" => "sku", "value" => "A1" } ] })

      recorded = WriteData.step_type.process(node, {})

      assert_equal [ "restock", "A1" ], recorded.values_at("name", "sku")
    end
  end
end
