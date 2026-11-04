require "test_helper"

module EasyFlow
  class ReadDataTest < ActiveSupport::TestCase
    class Shelf
      def reads = %w[stock]
    end

    setup { EasyFlow.data_source = Shelf.new }
    teardown { EasyFlow.data_source = nil }

    test "offers what the app says can be read" do
      assert_equal %w[stock], ReadData.step_type.settings.choices[:data]
    end
  end
end
