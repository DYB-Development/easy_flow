module EasyFlow
  module Steps
    class FillInTheBlank
      include Step

      Asked = Data.define(:id, :text)

      step_name "Fill in the blank"

      setting :question, type: :string
      setting :required, type: :boolean
      setting :accepted_answers, type: :list, required: true do
        setting :value, type: :string
      end

      names_by :question
      awaits_input
      drawn_by "easy_flow/steps/typing"
      answer_check { |node, value| "Type an answer to go on." if node.config["required"] && value.blank? }

      displays_by { |node| Asked.new(id: node.id.to_sym, text: node.config["question"]) }
    end
  end
end
