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

    def plain_value_is?(id, output_name)
      named = step(id)
      type = step_type(named)
      return true if type.nil? || type.outputs_for(named).empty?

      type.outputs.one? && type.outputs.first.name.to_s == output_name.to_s
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

    def item_value(key, state)
      visit = VisitKey.parse(key)
      box = holder_of(visit.step)
      items_of(box, latest_values(state))[visit.item - 1] if box && visit.item
    end

    def items_ended(id, state)
      box = step(id)
      ended = items_of(box, latest_values(state)).each_index.map { |index| item_values(box, index + 1, state) }
      failed = ended.count { |values| values.any? { |held, value| failed?(step(held), state.merge(held => value), {}) } }

      { "result" => failed.zero? ? "passed" : "failed", "items" => ended, "passed" => ended.size - failed, "failed" => failed }
    end

    def repeats?(node)
      step_type(node)&.repeats_held_steps? || false
    end

    def holder_of(key)
      steps.find { |node| repeats?(node) && Array(node.config["holds"]).include?(VisitKey.parse(key).step) }
    end

    def next_step(state, times = {})
      walk(state, times)[1]
    end

    def output(state, times = {})
      ended_setting(state, times, "output")
    end

    def end_mark(state, times = {})
      ended_setting(state, times, "mark")
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
      visits = Hash.new(0)
      while cursor && decided?(cursor, state) && visits[cursor.id].zero?
        visits[cursor.id] += 1
        left += 1 if step_type(cursor)&.awaits_input?
        cursor = successor(cursor, state)
      end
      left
    end

    private

    def ended_setting(state, times, name)
      ended = nil
      walk(state, times) { |cursor| ended = cursor }

      ended.config[name].presence if step_type(ended)&.ends_here?
    end

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
        held = repeats?(cursor) && walk_items(cursor, state, times, Path.new(recorded, latest, latest_times))
        return [ recorded, held ] if held
        return [ recorded, cursor.with(id: key) ] if pending?(cursor, key, state)

        if state.key?(key)
          recorded << key
          latest[cursor.id] = state[key]
          latest_times[cursor.id] = times[key] if times.key?(key)
          answered += 1 if step_type(cursor)&.awaits_input?
        end
        cursor = repeats?(cursor) ? box_exit(cursor) : successor(cursor, reached(state, recorded).merge(latest), latest_times)
      end

      [ recorded, nil ]
    end

    Path = Struct.new(:recorded, :latest, :latest_times)

    def walk_items(box, state, times, path)
      items_of(box, path.latest).each_index do |index|
        held = walk_item(box, index + 1, state, times, path)
        return held if held
      end
      nil
    end

    def walk_item(box, item, state, times, path)
      visits = Hash.new(0)
      recorded_at_visit = {}
      cursor = first_held(box)

      while cursor && held_by?(box, cursor)
        return if visits[cursor.id].positive? && recorded_at_visit[cursor.id] == path.recorded.size

        visits[cursor.id] += 1
        recorded_at_visit[cursor.id] = path.recorded.size
        key = item_key(cursor.id, item, visits[cursor.id])
        return cursor.with(id: key) if pending?(cursor, key, state)

        if state.key?(key)
          path.recorded << key
          path.latest[cursor.id] = state[key]
          path.latest_times[cursor.id] = times[key] if times.key?(key)
        end
        routed = reached(state, path.recorded).merge(path.latest)
        return if failed?(cursor, routed, path.latest_times)

        cursor = successor(cursor, routed, path.latest_times)
      end
    end

    def failed?(node, state, times)
      step_type(node)&.route(node, state, times).to_s == "failed"
    end

    def items_of(box, latest)
      step_id, output = step_type(box).list_named_by(box).split(".", 2)
      listed = latest[step_id]
      listed = listed[output] if listed.is_a?(Hash) && output
      listed.is_a?(Array) ? listed : []
    end

    def item_key(id, item, visit)
      VisitKey.new(step: id, item: item, visit: visit).to_s
    end

    def latest_values(state)
      state.keys.map { |key| VisitKey.parse(key) }.reject(&:item).group_by(&:step)
        .transform_values { |visits| state[visits.max_by(&:visit).to_s] }
    end

    def item_values(box, item, state)
      visits = state.keys.map { |key| VisitKey.parse(key) }.select { |visit| visit.item == item }
      Array(box.config["holds"]).filter_map do |held|
        latest = visits.select { |visit| visit.step == held }.max_by(&:visit)
        [ held, state[latest.to_s] ] if latest
      end.to_h
    end

    def held_by?(box, node)
      Array(box.config["holds"]).include?(node.id)
    end

    def first_held(box)
      entering = @document.edges_from(box.id).first
      entering && @document.node(entering.to)
    end

    def box_exit(box)
      held = Array(box.config["holds"])
      leaving = @document.edges.find { |edge| held.include?(edge.from) && !held.include?(edge.to) && edge.on.to_s != "failed" }
      leaving && @document.node(leaving.to)
    end

    def reached(state, recorded)
      state.reject { |key, _value| step(key) && !recorded.include?(key) }
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

      step_type(node)&.awaits_input? || acts?(node) || step_type(node)&.waits? || repeats?(node)
    end

    def acts?(node)
      step_type(node)&.acts? || false
    end

    def successor(node, state, times = {})
      return node if step_type(node)&.comes_back?(node, state)

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
