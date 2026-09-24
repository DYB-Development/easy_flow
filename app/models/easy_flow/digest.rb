module EasyFlow
  class Digest
    def initialize(document, registry: EasyFlow.registry)
      @document = document
      @registry = registry
    end

    def entry
      @document.node(@document.entry)
    end

    def step(id)
      @document.node(id)
    end

    def steps
      @document.nodes
    end

    def preceding(id)
      return [] unless @document.reachable.include?(id)

      @document.nodes.map(&:id).uniq
        .reject { |other| other == id || @document.reachable(without: other).include?(id) }
    end

    def routing_values(id)
      named = step(id)
      return [] unless named && step_type(named)&.routes?

      step_type(named).outputs.flat_map { |output| values_taken(output, named) }.map { |value| value["value"].to_s }
    end

    def values_taken(output, node)
      return output.values_for(node) unless output.from

      values_out_of(node.config[output.from.to_s])
    end

    def values_of(id, output_name)
      named = step(id)
      return [] unless named && output_name.present?

      step_type(named)&.values_of(output_name, named).to_a
    end

    def outputs_of(id)
      named = step(id)
      return [] unless named

      step_type(named)&.outputs.to_a.map { |output| { "value" => output.name.to_s, "label" => output.label } }
    end

    def values_out_of(id)
      named = step(id)
      return [] unless named

      step_type(named)&.outputs.to_a.flat_map { |output| output.values_for(named) }
    end

    def requirements(id)
      node = step(id)
      step_type(node)&.settings&.requirements_for(node.config).to_a
    end

    def next_step(state)
      walk(state).last
    end

    def state_on_path(state)
      state.slice(*walk(state).first)
    end

    private

    def walk(state)
      recorded = []
      visited = []
      cursor = entry

      while cursor && !visited.include?(cursor.id)
        return [ recorded, cursor ] if pending?(cursor, state)

        recorded << cursor.id if state.key?(cursor.id)
        visited << cursor.id
        cursor = successor(cursor, state)
      end

      [ recorded, nil ]
    end

    def pending?(node, state)
      return false if state.key?(node.id)

      step_type(node)&.awaits_input? || acts?(node)
    end

    def acts?(node)
      step_type(node)&.acts? || false
    end

    def successor(node, state)
      leaving = @document.edges_from(node.id)
      port = step_type(node)&.route(node, state)
      taken = port.nil? ? leaving.first : leaving.find { |edge| edge.on.to_s == port.to_s }

      taken && @document.node(taken.to)
    end

    def step_type(node)
      @registry.fetch(node.type) if node && @registry.registered?(node.type)
    end
  end
end
