module EasyFlow
  class QuestionRunner < Runner
    def question_text(id)
      Steps::Question.asked(step(id)&.config)
    end

    def choice_label(id, value)
      chosen = Steps::Question.choices_in(step(id)).find { |choice| choice.value == value }

      chosen&.label.presence || value
    end
  end
end
