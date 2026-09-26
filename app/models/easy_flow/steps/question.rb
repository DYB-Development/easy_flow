module EasyFlow
  module Steps
    class Question
      include Step

      step_name "Question"

      setting :question, type: :string
      setting :category, type: :string
      setting :required, type: :boolean
      setting :answers, type: :list, required: true do
        setting :value, type: :string
        setting :label, type: :string
        setting :weight, type: :integer
      end

      output :answer, type: :string, label: "Answer", values: ->(node) { Question.offered(node.config) }

      names_by :question
      awaits_input
      answer_check { |node, value| "Fill this in to go on." if node.config["required"] && value.blank? }

      displays_by { |node| Asked.new(id: node.id.to_sym, text: asked(node.config), choices: choices_in(node)) }

      def self.asked(step)
        step.to_h["question"] || step.to_h["text"]
      end

      def self.answers_of(step)
        Array(step.to_h["answers"] || step.to_h["options"])
      end

      def self.offered(step)
        answers_of(step).map do |answer|
          { "value" => answer["value"], "label" => answer["label"].presence || answer["value"] }
        end
      end

      def self.choices_in(node)
        answers_of(node.config).map { |answer| choice_from(answer) }
      end

      def self.choice_from(answer)
        return Choice.new(value: answer) unless answer.is_a?(Hash)

        Choice.new(value: answer["value"], label: answer["label"], hint: answer["hint"])
      end

      def self.category_of(step)
        step.to_h["category"] || step.to_h["tag"]
      end
    end
  end
end
