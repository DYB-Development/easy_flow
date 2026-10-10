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
      @document.node(id.to_s.split("@").first)
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

      declared = step_type(named)&.outputs_for(named).to_a.map { |output| { "value" => output.name.to_s, "label" => output.label } }
      records_a_value?(named) ? declared + CompletedAt.outputs : declared
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

    def next_step(state, times = {})
      walk(state, times)[1]
    end

    def output(state, times = {})
      ended = nil
      walk(state, times) { |cursor| ended = cursor }

      ended.config["output"].presence if step_type(ended)&.ends_here?
    end

    def ended_at_end?(state, times = {})
      ended = nil
      _recorded, waiting, = walk(state, times) { |cursor| ended = cursor }

      waiting.nil? && step_type(ended)&.ends_here? || false
    end

    def stopped_on_loop(state, times = {})
      walk(state, times)[2]
    end

    def state_on_path(state, times = {})
      state.slice(*walk(state, times).first)
    end

    def questions_left(state)
      cursor = next_step(state) && step(next_step(state).id)
      left = 0
      while cursor && decided?(cursor, state)
        left += 1 if step_type(cursor)&.awaits_input?
        cursor = successor(cursor, state)
      end
      left
    end

    private

    def walk(state, times = {})
      recorded = []
      latest = {}
      latest_times = {}
      visits = Hash.new(0)
      answers_at_visit = {}
      answered = 0
      cursor = entry

      while cursor
        return [ recorded, nil, cursor.id ] if visits[cursor.id].positive? && answers_at_visit[cursor.id] == answered

        yield cursor if block_given?
        visits[cursor.id] += 1
        answers_at_visit[cursor.id] = answered
        key = visit_key(cursor.id, visits[cursor.id])
        return [ recorded, cursor.with(id: key) ] if pending?(cursor, key, state)

        if state.key?(key)
          recorded << key
          latest[cursor.id] = state[key]
          latest_times[cursor.id] = times[key] if times.key?(key)
          answered += 1 if step_type(cursor)&.awaits_input?
        end
        cursor = successor(cursor, state.merge(latest), latest_times)
      end

      [ recorded, nil ]
    end

    def records_a_value?(node)
      type = step_type(node)
      type.present? && (type.awaits_input? || type.acts? || type.waits?)
    end

    def decided?(node, state)
      return true unless step_type(node)&.routes?

      step_type(node).settings.naming_steps.all? { |setting| state.key?(node.config[setting.to_s].to_s) }
    end

    def visit_key(id, visit)
      visit == 1 ? id : "#{id}@#{visit}"
    end

    def pending?(node, key, state)
      return false if state.key?(key)

      step_type(node)&.awaits_input? || acts?(node) || step_type(node)&.waits? || false
    end

    def acts?(node)
      step_type(node)&.acts? || false
    end

    def successor(node, state, times = {})
      leaving = @document.edges_from(node.id)
      port = step_type(node)&.route(node, state, times)
      taken = port.nil? ? leaving.first : leaving.find { |edge| edge.on.to_s == port.to_s }

      taken && @document.node(taken.to)
    end

    def step_type(node)
      @registry.fetch(node.type) if node && @registry.registered?(node.type)
    end
  end
end
