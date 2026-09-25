module EasyFlow
  class Compare
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<= }.freeze

    step_name "Compare"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :amount, type: :float, required: true

    def route(node, state)
      answer = state[node.config["step"]]
      answer = answer[node.config["output"]] if answer.is_a?(Hash)
      number = Float(answer.to_s, exception: false)
      return false if number.nil?

      number.public_send(COMPARISONS.fetch(node.config["comparison"]), node.config["amount"])
    end
  end
end
