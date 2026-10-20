require "test_helper"

module EasyFlow
  module Steps
    class FillInTheBlankTest < ActiveSupport::TestCase
      test "an admin can give it a list of accepted answers on the canvas" do
        assert_equal({ value: :string }, EasyFlow.registry.fetch(:fill_in_the_blank).settings.record_fields[:accepted_answers])
      end

      test "a required fill in the blank refuses an answer of only spaces and says why" do
        node = Node.new(id: "capital", type: "fill_in_the_blank", config: { "required" => true })

        assert_equal "Type an answer to go on.", FillInTheBlank.step_type.answer_problem(node, "  ")
      end

      test "an admin can set a category a host can group it by" do
        assert_equal :string, FillInTheBlank.step_type.settings.fields[:category]
      end
    end
  end
end
