module EasyFlow
  class Switch
    include Step

    step_name "Switch"

    setting :step, type: :previous_step

    output :choice, type: :string, label: "Choice", from: :step

    summarizes_by { |node| "branches on #{node.config["step"]}" if node.config["step"].present? }

    def route(node, state)
      state[node.config["step"]]
    end
  end
end
