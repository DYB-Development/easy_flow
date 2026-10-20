module EasyFlow
  module Steps
    class FillInTheBlank
      include Step

      step_name "Fill in the blank"

      setting :question, type: :string
      setting :accepted_answers, type: :list, required: true do
        setting :value, type: :string
      end

      names_by :question
      awaits_input
    end
  end
end
