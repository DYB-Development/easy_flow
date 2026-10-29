require "test_helper"

module EasyFlow
  module Steps
    class FillInTheBlankTest < ActiveSupport::TestCase
      test "hands the page drawing it the address of its picture" do
        store = Object.new
        store.define_singleton_method(:url_of) { |reference| "/pictures/#{reference}" }
        stored_with, EasyFlow.picture_store = EasyFlow.picture_store, store
        node = Node.new(id: "capital", type: "fill_in_the_blank", config: { "question" => "Capital?", "picture" => "picture-1" })

        assert_equal "/pictures/picture-1", FillInTheBlank.step_type.display_of(node).picture_url
      ensure
        EasyFlow.picture_store = stored_with
      end

      test "declares a setting for a picture shown with the question" do
        assert_equal :picture, FillInTheBlank.step_type.settings.fields[:picture]
      end

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
