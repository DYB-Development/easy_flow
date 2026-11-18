module EasyFlow
  class Compare
    include Step

    COMPARISONS = { "more than" => :>, "less than" => :<, "at least" => :>=, "at most" => :<= }.freeze

    step_name "Compare"

    setting :step, type: :previous_step
    setting :output, outputs_of: :step
    setting :comparison, type: :select, options: COMPARISONS.keys, required: true
    setting :amount, type: :float, required: true

    output :result, type: :boolean, values: [ true, false ]

    summarizes_by { |node| [ node.config.values_at("step", "output").compact_blank.join("."), node.config["comparison"], Compare.amount_of(node.config["amount"]) ].compact_blank.join(" ") }

    def self.amount_of(value)
      number = Float(value.to_s, exception: false)
      return value if number.nil?

      number == number.round ? number.to_i.to_s : number.to_s
    end

    def route(node, state, times)
      number = Float(CompletedAt.value_of(state, times, *node.config.values_at("step", "output")).to_s, exception: false)
      return false if number.nil?

      number.public_send(COMPARISONS.fetch(node.config["comparison"]), node.config["amount"])
    end
  end
end
