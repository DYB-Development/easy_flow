module EasyFlow
  class RunView
    def initialize(version, steps: {}, selected: nil, ended_at: nil, registry: EasyFlow.registry)
      @document = Document.new(version.definition || {}, registry: registry)
      @steps = steps.to_h.transform_keys(&:to_s)
      @selected = selected
      @ended_at = ended_at&.to_s
      @registry = registry
    end

    def to_h
      { "nodes" => nodes, "edges" => edges, "selected" => @selected&.to_s }
    end

    private

    def nodes
      @document.nodes.map { |node| drawn_step(node) }
    end

    def edges
      @document.edges.each_with_index.map do |edge, index|
        { "id" => "#{edge.from}-#{edge.to}-#{index}", "source" => edge.from, "target" => edge.to, "label" => edge.on&.to_s }
      end
    end

    def placed
      @placed ||= Layout.new(@document).positions
    end

    def holds(node)
      Array(node.config["holds"]) if step_type_for(node)&.holds_steps?
    end

    def step_type_for(node)
      @registry.fetch(node.type) if @registry.registered?(node.type)
    end

    def drawn_step(node)
      shown = @steps.fetch(node.id, {}).to_h.symbolize_keys

      { "id" => node.id, "type" => node.type, "label" => Name.of(node, @registry), "state" => state_of(node, shown), "status" => shown[:status], "address" => shown[:address], "version" => shown[:version],
        "holds" => holds(node), **header_of(node), **placed.fetch(node.id, {}) }
    end

    def state_of(node, shown)
      return "done" if node.id == @ended_at
      return shown[:state]&.to_s unless step_type_for(node)&.begins_here?

      started? ? "done" : "pending"
    end

    def started?
      @steps.values.map { |shown| shown.to_h.symbolize_keys[:state].to_s }.any? { |state| state.present? && state != "pending" }
    end

    def header_of(node)
      return {} unless step_type_for(node)&.holds_steps?

      { "config" => node.config, "fields" => step_type_for(node).settings.fields.transform_keys(&:to_s).transform_values(&:to_s) }
    end
  end
end
