module EasyFlow
  class QuestionRunner < Runner
    def question_text(id)
      Steps::Question.asked(step(id)&.config)
    end

    def choice_label(id, value)
      return value.map { |ticked| choice_label(id, ticked) }.to_sentence if value.is_a?(Array)

      labelled = labelled_by_step_type(id, value)
      return labelled if labelled.present?

      chosen = Steps::Question.choices_in(step(id)).find { |choice| choice.value == value }

      chosen&.label.presence || value
    end

    private

    def labelled_by_step_type(id, value)
      node = step(id)
      EasyFlow.registry.fetch(node.type).answer_label(node, value) if node && EasyFlow.registry.registered?(node.type)
    end
  end
end
