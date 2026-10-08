module EasyFlow
  ChosenFlow = Data.define(:flow_id, :number) do
    def self.of(node, registry: EasyFlow.registry, run: nil)
      step_type = registry.fetch(node.type) if registry.registered?(node.type)
      return worked_out((run && step_type.flow_chosen_from_run(node, run)) || {}) if step_type&.chooses_flow_from_run?

      chosen = step_type&.flow_chosen_by(node)
      return worked_out(chosen) if chosen

      new(flow_id: node.config["flow"].presence, number: node.config["version"].presence)
    end

    def self.worked_out(chosen)
      new(flow_id: chosen[:flow].presence, number: chosen[:version].presence)
    end

    def name
      [ flow&.title, ("version #{number}" if number) ].compact.join(", ").presence
    end

    def flow
      Definition.find_by(id: flow_id) if flow_id
    end

    def version
      flow&.definition_versions&.find_by(number: number)
    end
  end
end
