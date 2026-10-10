module EasyFlow
  class Compare
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<= }.freeze

    step_name "Compare"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :amount, type: :float, required: true

    output :result, type: :boolean, values: [ true, false ]

    def route(node, state, times)
      number = Float(read(node, state, times).to_s, exception: false)
      return false if number.nil?

      number.public_send(COMPARISONS.fetch(node.config["comparison"]), node.config["amount"])
    end

    private

    def read(node, state, times)
      step, output = node.config.values_at("step", "output")
      return times[step] && AnsweredAt.read(output, times[step]) if AnsweredAt::OUTPUTS.key?(output)

      answer = state[step]
      answer.is_a?(Hash) ? answer[output] : answer
    end
  end
end
