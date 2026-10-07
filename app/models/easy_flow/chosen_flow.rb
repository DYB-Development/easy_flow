module EasyFlow
  ChosenFlow = Data.define(:flow_id, :number) do
    def self.of(node)
      new(flow_id: node.config["flow"].presence, number: node.config["version"].presence)
    end

    def flow
      Definition.find_by(id: flow_id) if flow_id
    end

    def version
      flow&.definition_versions&.find_by(number: number)
    end
  end
end
