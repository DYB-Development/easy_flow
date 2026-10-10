module EasyFlow
  class CompareTwoValues
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<=, "equal to" => :== }.freeze

    step_name "Compare two values"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :other_step, type: :previous_step
    setting :other_output, outputs_of: :other_step
    setting :amount, type: :float

    output :result, type: :boolean, values: [ true, false ]

    def route(node, state)
      first = number(side(state[node.config["step"]], node.config["output"]))
      second = number(side(state[node.config["other_step"]], node.config["other_output"]))
      return false if first.nil? || second.nil?

      first.public_send(COMPARISONS.fetch(node.config["comparison"]), second + node.config["amount"].to_f)
    end

    private

    def side(answer, output)
      answer.is_a?(Hash) ? answer[output] : answer
    end

    def number(answer)
      Float(answer.to_s, exception: false)
    end
  end
end
