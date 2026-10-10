module EasyFlow
  class AllOrAny
    include Step

    step_name "All of or Any of"

    def route(node, state, times)
      Array(node.config["comparisons"]).all? { |comparison| holds?(comparison, state, times) }
    end

    private

    def holds?(comparison, state, times)
      CompareTwoValues.step_type.route(Node.new(id: "comparison", type: "compare_two_values", config: comparison), state, times)
    end
  end
end
