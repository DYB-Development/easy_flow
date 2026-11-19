require "test_helper"

module EasyFlow
  class ForEachTest < ActiveSupport::TestCase
    test "a for_each step holds steps and offers a list, a concurrency and an item-failure rule" do
      step_type = ForEach.step_type

      assert_equal [ true, { list: :string, concurrency: :integer, on_item_failure: :select } ], [ step_type.holds_steps?, step_type.settings.fields ]
    end
  end
end
