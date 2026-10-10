module EasyFlow
  class Condition
    include Step

    step_name "Condition"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step, required: true
    setting :comparison, type: :select, options: [ "is", "is not" ], required: true
    setting :answer, from: :output, required: true

    output :result, type: :boolean, values: [ true, false ]

    names_by { |node| node.config.values_at("step", "comparison", "answer").compact_blank.join(" ").presence }

    def route(node, state)
      answer = state[node.config["step"]]
      answer = answer[node.config["output"]] if answer.is_a?(Hash)
      matched = answer == node.config["answer"]

      node.config["comparison"] == "is not" ? !matched : matched
    end
  end
end
