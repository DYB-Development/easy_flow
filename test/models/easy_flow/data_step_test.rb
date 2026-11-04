require "test_helper"

module EasyFlow
  class DataStepTest < ActiveSupport::TestCase
    class Shelf
      def initialize(&answer)
        @answer = answer
      end

      def reads = %w[stock]
      def writes = %w[restock]

      def carry_out(name, values)
        @answer.call(name, values)
      end
    end

    teardown { EasyFlow.data_source = nil }

    def answering(&answer)
      EasyFlow.data_source = Shelf.new(&answer)
    end

    def read(config = {})
      Node.new(id: "lookup", type: "read_data", config: { "data" => "stock" }.merge(config))
    end

    def read_processed(config = {})
      ReadData.step_type.process(read(config), {})
    end

    test "records what the app answers to a read given the input values" do
      answering { |name, values| { "name" => name, "sku" => values["sku"] } }

      recorded = read_processed("inputs" => [ { "name" => "sku", "value" => "A1" } ])

      assert_equal [ "stock", "A1" ], recorded.values_at("name", "sku")
    end

    test "records what the app answers to a write given the input values" do
      answering { |name, values| { "name" => name, "sku" => values["sku"] } }
      node = Node.new(id: "add", type: "write_data", config: { "data" => "restock", "inputs" => [ { "name" => "sku", "value" => "A1" } ] })

      recorded = WriteData.step_type.process(node, {})

      assert_equal [ "restock", "A1" ], recorded.values_at("name", "sku")
    end

    test "records an answer that is not a hash under answer" do
      answering { "A1" }

      assert_equal "A1", read_processed["answer"]
    end

    test "records a hash answer under names written as strings" do
      answering { { title: "Boots" } }

      assert_equal "Boots", read_processed["title"]
    end

    test "records passed when the app answers" do
      answering { "A1" }

      assert_equal "passed", read_processed["result"]
    end

    test "records failed with the reason when the app raises" do
      answering { raise "The shelf is closed" }

      assert_equal({ "result" => "failed", "reason" => "The shelf is closed" }, read_processed)
    end

    test "keeps its own result when the answer holds a key named result" do
      answering { { "result" => "unchanged" } }

      assert_equal "passed", read_processed["result"]
    end
  end
end
