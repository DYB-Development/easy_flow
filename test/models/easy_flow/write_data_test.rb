require "test_helper"

module EasyFlow
  class WriteDataTest < ActiveSupport::TestCase
    class Shelf
      def writes = %w[restock]
    end

    setup { EasyFlow.data_source = Shelf.new }
    teardown { EasyFlow.data_source = nil }

    test "offers what the app says can be written" do
      assert_equal %w[restock], WriteData.step_type.settings.choices[:data]
    end
  end
end
