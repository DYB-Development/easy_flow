module EasyFlow
  class CompareTwoValues
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<=, "equal to" => :== }.freeze

    step_name "Compare two values"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :other_step, type: :previous_step, optional: true
    setting :other_output, outputs_of: :other_step
    setting :amount, type: :float

    output :result, type: :boolean, values: [ true, false ]

    summarizes_by { |node| CompareTwoValues.summarized(node.config) }

    def self.summarized(config)
      [ config.values_at("step", "output").compact_blank.join("."), config["comparison"], config.values_at("other_step", "other_output").compact_blank.join("."), "+", Compare.amount_of(config["amount"]) ].compact_blank.join(" ")
    end

    def route(node, state, times)
      first = number(CompletedAt.value_of(state, times, *node.config.values_at("step", "output")))
      second = node.config["other_step"].present? ? number(CompletedAt.value_of(state, times, *node.config.values_at("other_step", "other_output"))) : 0.0
      return false if first.nil? || second.nil?

      first.public_send(COMPARISONS.fetch(node.config["comparison"]), second + node.config["amount"].to_f)
    end

    private

    def number(value)
      Float(value.to_s, exception: false)
    end
  end
end
