module EasyFlow
  class CompareTwoValues
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :< }.freeze

    step_name "Compare two values"

    def route(node, state)
      state[node.config["step"]].public_send(COMPARISONS.fetch(node.config["comparison"]), state[node.config["other_step"]])
    end
  end
end
