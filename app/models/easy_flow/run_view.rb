module EasyFlow
  class RunView
    def initialize(version, steps: {}, selected: nil, registry: EasyFlow.registry)
      @document = Document.new(version.definition || {}, registry: registry)
      @steps = steps.to_h.transform_keys(&:to_s)
      @selected = selected
      @registry = registry
    end

    def to_h
      { "nodes" => nodes }
    end

    private

    def nodes
      @document.nodes.map { |node| drawn_step(node) }
    end

    def drawn_step(node)
      shown = @steps.fetch(node.id, {}).to_h.symbolize_keys

      { "id" => node.id, "state" => shown[:state]&.to_s, "status" => shown[:status], "address" => shown[:address], "version" => shown[:version] }
    end
  end
end
