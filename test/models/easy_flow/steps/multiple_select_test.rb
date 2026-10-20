require "test_helper"

module EasyFlow
  module Steps
    class MultipleSelectTest < ActiveSupport::TestCase
      test "an admin can give each answer a value, a label and a weight on the canvas" do
        assert_equal({ value: :string, label: :string, weight: :integer }, EasyFlow.registry.fetch(:multiple_select).settings.record_fields[:answers])
      end

      test "a required multiple select refuses an answer with nothing picked and says why" do
        node = Node.new(id: "primes", type: "multiple_select", config: { "required" => true })

        assert_equal "Pick at least one answer to go on.", MultipleSelect.step_type.answer_problem(node, [ "" ])
      end
    end
  end
end
