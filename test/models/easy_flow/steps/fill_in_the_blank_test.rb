require "test_helper"

module EasyFlow
  module Steps
    class FillInTheBlankTest < ActiveSupport::TestCase
      test "an admin can give it a list of accepted answers on the canvas" do
        assert_equal({ value: :string }, EasyFlow.registry.fetch(:fill_in_the_blank).settings.record_fields[:accepted_answers])
      end
    end
  end
end
