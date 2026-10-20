require "test_helper"

module EasyFlow
  module Steps
    class MultipleSelectTest < ActiveSupport::TestCase
      test "an admin can give each answer a value, a label and a weight on the canvas" do
        assert_equal({ value: :string, label: :string, weight: :integer }, EasyFlow.registry.fetch(:multiple_select).settings.record_fields[:answers])
      end
    end
  end
end
