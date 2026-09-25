module EasyFlow
  class Compare
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :< }.freeze

    step_name "Compare"

    setting :step, type: :previous_step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :amount, type: :float, required: true

    def route(node, state)
      state[node.config["step"]].public_send(COMPARISONS.fetch(node.config["comparison"]), node.config["amount"])
    end
  end
end
