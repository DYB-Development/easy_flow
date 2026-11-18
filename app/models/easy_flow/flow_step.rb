module EasyFlow
  class FlowStep
    include Step

    step_name "Flow"

    starts_a_flow

    setting :flow, type: :flow
    setting :version, type: :integer

    output :result, values: ->(node) { FlowStep.endings_of(node) }

    waits_until { |_node, _state| false }

    names_by { |node| ChosenFlow.of(node).name }
    summarizes_by { |node| FlowStep.steps_in(node)&.then { |count| "#{count} #{"step".pluralize(count)}" } }

    def self.steps_in(node)
      version = ChosenFlow.of(node).version
      Array(version.definition.to_h["nodes"]).count { |step| %w[start terminal].exclude?(step["type"]) } if version
    end

    def self.endings_of(node)
      version = ChosenFlow.of(node).version
      Array(version&.definition.to_h["nodes"]).select { |step| step["type"] == "terminal" }.map { |step| step["output"].presence || "ended" }.uniq
    end

    def route(node, state)
      state[node.id]
    end
  end
end
