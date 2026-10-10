module EasyFlow
  class AllOrAny
    include Step

    step_name "All of or Any of"

    setting :join, type: :select, options: [ "all of", "any of" ], label: "Must hold", required: true
    setting :comparisons, type: :list, required: true do
      setting :step, type: :previous_step, required: true
      setting :output, outputs_of: :step
      setting :comparison, type: :select, options: CompareTwoValues::COMPARISONS.keys, required: true
      setting :amount, type: :float
      setting :other_step, type: :previous_step, label: "Second step"
      setting :other_output, outputs_of: :other_step, label: "Second step's output"
    end

    output :result, type: :boolean, values: [ true, false ]

    def route(node, state, times)
      comparisons = Array(node.config["comparisons"])
      return false if comparisons.empty?

      held = ->(comparison) { holds?(comparison, state, times) }
      node.config["join"] == "any of" ? comparisons.any?(&held) : comparisons.all?(&held)
    end

    private

    def holds?(comparison, state, times)
      CompareTwoValues.step_type.route(Node.new(id: "comparison", type: "compare_two_values", config: comparison), state, times)
    end
  end
end
