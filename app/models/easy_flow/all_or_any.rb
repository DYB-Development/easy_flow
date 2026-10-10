module EasyFlow
  class AllOrAny
    include Step

    step_name "All of or Any of"

    def route(node, state, times)
      comparisons = Array(node.config["comparisons"])
      held = ->(comparison) { holds?(comparison, state, times) }
      node.config["join"] == "any of" ? comparisons.any?(&held) : comparisons.all?(&held)
    end

    private

    def holds?(comparison, state, times)
      CompareTwoValues.step_type.route(Node.new(id: "comparison", type: "compare_two_values", config: comparison), state, times)
    end
  end
end
