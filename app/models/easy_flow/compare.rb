module EasyFlow
  class Compare
    include Step

    step_name "Compare"

    setting :step, type: :previous_step
    setting :comparison, type: :select, options: [ "more than" ], required: true
    setting :amount, type: :float, required: true

    def route(node, state)
      state[node.config["step"]] > node.config["amount"]
    end
  end
end
