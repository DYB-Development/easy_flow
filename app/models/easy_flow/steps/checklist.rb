module EasyFlow
  module Steps
    class Checklist
      include Step

      step_name "Checklist"

      setting :question, type: :string
      setting :answers, type: :list, required: true do
        setting :value, type: :string
        setting :label, type: :string
      end

      names_by :question
      awaits_input

      displays_by { |node| Asked.new(id: node.id.to_sym, text: node.config["question"], choices: Question.choices_in(node)) }
    end
  end
end
