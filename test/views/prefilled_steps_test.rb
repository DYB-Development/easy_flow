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

    test "a fill-in-the-blank question drawn with a chosen answer has it typed in its box" do
      render partial: "easy_flow/steps/typing", locals: { step: Steps::FillInTheBlank::Asked.new(id: :capital, text: "Capital of France?"), chosen: "Paris" }

      assert_select "input[name='answers[capital]'][value=Paris]"
    end

    test "a question drawn without a chosen answer has no option selected" do
      render partial: "easy_flow/steps/choosing", locals: { step: question }

      assert_select "input[type=radio][checked]", count: 0
    end

    private

    def question
      Asked.new(id: :pick, text: "Pick one", choices: %w[a b].map { |value| Choice.new(value: value) })
    end
  end
end
