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
      @document.nodes.reject { |node| bookend?(node) }.map { |node| drawn_step(node) }
    end

    def placed
      @placed ||= Layout.new(@document).positions
    end

    def bookend?(node)
      step_type = step_type_for(node)
      step_type.present? && (step_type.begins_here? || step_type.ends_here?)
    end

    def step_type_for(node)
      @registry.fetch(node.type) if @registry.registered?(node.type)
    end

    def drawn_step(node)
      shown = @steps.fetch(node.id, {}).to_h.symbolize_keys

      { "id" => node.id, "type" => node.type, "label" => Name.of(node, @registry), "state" => shown[:state]&.to_s, "status" => shown[:status], "address" => shown[:address], "version" => shown[:version], **placed[node.id] }
    end
  end
end
