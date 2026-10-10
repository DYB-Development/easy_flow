module EasyFlow
  class Count
    include Step

    step_name "Count"

    setting :step, type: :previous_step

    def process(node, state)
      visits(node, state).count { |answer| counted?(node, answer) }
    end

    private

    def visits(node, state)
      state.select { |key, _| key.to_s.split("@").first == node.config["step"] }.values
    end

    def counted?(node, answer)
      answer = answer[node.config["output"]] if answer.is_a?(Hash)
      node.config["answer"].blank? || answer.to_s == node.config["answer"].to_s
    end
  end
end
