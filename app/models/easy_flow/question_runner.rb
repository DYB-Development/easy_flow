module EasyFlow
  class QuestionRunner < Runner
    def question_text(id)
      Steps::Question.asked(step(id)&.config)
    end

    def choice_label(id, value)
      return value.map { |ticked| choice_label(id, ticked) }.to_sentence if value.is_a?(Array)

      chosen = Steps::Question.choices_in(step(id)).find { |choice| choice.value == value }

      chosen&.label.presence || value
    end
  end
end
