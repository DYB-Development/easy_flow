require "test_helper"

module EasyFlow
  module Steps
    class MultipleSelectTest < ActiveSupport::TestCase
      test "declares a setting for a picture shown with the question" do
        assert_equal :picture, MultipleSelect.step_type.settings.fields[:picture]
      end

      test "an admin can give each answer a value, a label and a weight on the canvas" do
        assert_equal({ value: :string, label: :string, weight: :integer }, EasyFlow.registry.fetch(:multiple_select).settings.record_fields[:answers])
      end

      test "a required multiple select refuses an answer with nothing picked and says why" do
        node = Node.new(id: "primes", type: "multiple_select", config: { "required" => true })

        assert_equal "Pick at least one answer to go on.", MultipleSelect.step_type.answer_problem(node, [ "" ])
      end

      test "an admin can set a category a host can group it by" do
        assert_equal :string, MultipleSelect.step_type.settings.fields[:category]
      end
    end
  end
end
