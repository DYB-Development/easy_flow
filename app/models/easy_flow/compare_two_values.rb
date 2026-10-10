module EasyFlow
  class CompareTwoValues
    include Step

    step_name "Compare two values"

    def route(node, state)
      state[node.config["step"]] > state[node.config["other_step"]]
    end
  end
end
