require "test_helper"

module EasyFlow
  class PrefilledStepsTest < ActionView::TestCase
    helper KeystoneUiHelper

    test "a single-choice question drawn with a chosen answer has that option selected" do
      render partial: "easy_flow/steps/choosing", locals: { step: question, chosen: "b" }

      assert_select "input[type=radio][value=b][checked]"
    end

    test "a multiple-select question drawn with chosen answers has each of them ticked" do
      render partial: "easy_flow/steps/ticking", locals: { step: question, chosen: %w[a b] }

      assert_select "input[type=checkbox][checked]", count: 2
    end

    private

    def question
      Asked.new(id: :pick, text: "Pick one", choices: %w[a b].map { |value| Choice.new(value: value) })
    end
  end
end
