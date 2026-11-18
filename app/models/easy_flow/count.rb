module EasyFlow
  class Count
    include Step

    step_name "Count"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :answer, from: :output

    output :count, type: :integer

    names_by { |node| [ "Count", *node.config.values_at("step", "answer") ].compact_blank.join(" ") }
    summarizes_by { |node| Count.summarized(node.config) }

    def self.summarized(config)
      return if config["step"].blank?

      counted = config.values_at("step", "output").compact_blank.join(".")
      config["answer"].blank? ? "counts every answer to #{counted}" : "counts #{counted} is #{config["answer"]}"
    end

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
