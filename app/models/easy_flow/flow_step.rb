module EasyFlow
  class FlowStep
    include Step

    step_name "Flow"

    setting :flow, type: :flow
    setting :version, type: :integer

    output :result, values: ->(node) { FlowStep.endings_of(node) }

    waits_until { |_node, _state| false }

    def self.endings_of(node)
      version = Definition.find_by(id: node.config["flow"])&.definition_versions&.find_by(number: node.config["version"])
      Array(version&.definition.to_h["nodes"]).select { |step| step["type"] == "terminal" }.filter_map { |step| step["output"].presence }.uniq
    end

    def route(node, state)
      state[node.id]
    end
  end
end
