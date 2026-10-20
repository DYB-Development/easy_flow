module EasyFlow
  module Steps
    class MultipleSelect
      include Step

      step_name "Multiple select"

      setting :question, type: :string
      setting :answers, type: :list, required: true do
        setting :value, type: :string
        setting :label, type: :string
        setting :weight, type: :integer
      end

      names_by :question
      awaits_input
    end
  end
end
