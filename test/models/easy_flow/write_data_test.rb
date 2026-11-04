require "test_helper"

module EasyFlow
  class WriteDataTest < ActiveSupport::TestCase
    class Shelf
      def reads
        []
      end

      def writes
        %w[restock]
      end
    end

    setup { EasyFlow.data_source = Shelf.new }
    teardown { EasyFlow.data_source = nil }

    test "offers what the app says can be written" do
      assert_equal %w[restock], WriteData.step_type.settings.choices[:data]
    end

    test "offers no choices when the app has set no data source" do
      EasyFlow.data_source = nil

      assert_empty WriteData.step_type.settings.choices[:data]
    end

    test "is on the canvas's add menu with what can be written" do
      palette = Canvas.new(Document.new({})).to_h["palette"]

      assert_equal %w[restock], palette.find { |entry| entry["type"] == "write_data" }["choices"]["data"]
    end
  end
end
