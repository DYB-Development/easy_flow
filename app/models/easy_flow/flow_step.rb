module EasyFlow
  class FlowStep
    include Step

    step_name "Flow"

    starts_a_flow

    setting :flow, type: :flow
    setting :version, type: :integer

    output :result, values: ->(node) { FlowStep.endings_of(node) }

    waits_until { |_node, _state| false }

    names_by { |node| [ Definition.find_by(id: node.config["flow"])&.title, ("version #{node.config["version"]}" if node.config["version"].present?) ].compact.join(", ").presence }

    def self.endings_of(node)
      version = ChosenFlow.of(node).version
      Array(version&.definition.to_h["nodes"]).select { |step| step["type"] == "terminal" }.filter_map { |step| step["output"].presence }.uniq
    end

    def route(node, state)
      state[node.id]
    end
  end
end
