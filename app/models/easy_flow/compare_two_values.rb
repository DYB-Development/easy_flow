module EasyFlow
  class CompareTwoValues
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<=, "equal to" => :== }.freeze

    step_name "Compare two values"

    def route(node, state)
      first = number(state[node.config["step"]])
      second = number(state[node.config["other_step"]])
      return false if first.nil? || second.nil?

      first.public_send(COMPARISONS.fetch(node.config["comparison"]), second + node.config["amount"].to_f)
    end

    private

    def number(answer)
      Float(answer.to_s, exception: false)
    end
  end
end
