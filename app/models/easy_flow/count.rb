module EasyFlow
  class Count
    include Step

    step_name "Count"

    setting :step, type: :previous_step

    def process(node, state)
      state.keys.count { |key| key.to_s.split("@").first == node.config["step"] }
    end
  end
end
