module EasyFlow
  class Canvas
    def initialize(document, registry: EasyFlow.registry)
      @document = document
      @registry = registry
    end

    def to_h
      { "nodes" => nodes, "edges" => edges, "palette" => palette, "violations" => violations }
    end

    private

    def nodes
      @document.nodes.map { |node| drawn_step(node) } + waiting.map { |gap| drawn_placeholder(gap) }
    end

    def drawn_step(node)
      { "id" => node.id, "type" => node.type, "label" => label_for(node),
        "config" => node.config, "ports" => [], "ends_here" => ends_here?(node), "begins_here" => begins_here?(node),
        "loose" => loose?(node), "choices" => choices_for(node), "placeholder" => false, **placed[node.id] }
    end

    def drawn_placeholder(gap)
      { "id" => gap[:id], "type" => "placeholder", "label" => gap[:on], "config" => {}, "ports" => [],
        "ends_here" => false, "begins_here" => false, "loose" => false, "choices" => {},
        "placeholder" => true, "from" => gap[:from], "on" => gap[:on], **placed[gap[:id]] }
    end

    def edges
      drawn.edges.each_with_index.map do |edge, index|
        { "id" => "#{edge.from}-#{edge.to}-#{index}", "source" => edge.from, "target" => edge.to, "label" => edge.on&.to_s,
          "placeholder" => waiting.any? { |gap| gap[:id] == edge.to } }.merge(routing(edge, placed))
      end
    end

    def placed
      @placed ||= Layout.new(drawn).positions
    end

    def drawn
      @drawn ||= Document.new(@document.to_h.merge(
        "nodes" => Array(@document.to_h["nodes"]) + waiting.map { |gap| { "id" => gap[:id], "type" => "placeholder" } },
        "edges" => Array(@document.to_h["edges"]) + waiting.map { |gap| { "from" => gap[:from], "to" => gap[:id], "on" => gap[:on] } }
      ), registry: @registry)
    end

    def waiting
      @waiting ||= @document.nodes.flat_map { |node| gaps_after(node) }
    end

    def gaps_after(node)
      wired = @document.edges_from(node.id).map { |edge| edge.on.to_s }
      results = digest.routing_values(node.id)
      return [ { id: "#{node.id}--", from: node.id, on: nil } ] if results.empty? && leads_nowhere?(node)

      results.reject { |value| wired.include?(value) }
        .map { |value| { id: "#{node.id}--#{value}", from: node.id, on: value } }
    end

    def leads_nowhere?(node)
      !ends_here?(node) && !loose?(node) && @document.edges_from(node.id).none?
    end

    def routing(edge, placed)
      from = placed[edge.from]
      to = placed[edge.to]
      return { "leaves" => "bottom", "enters" => "top", "route" => "straight" } unless from && to

      return alongside_routing(from, to) unless to["row"] > from["row"]

      { "leaves" => "bottom", "enters" => "top",
        "route" => to["column"] == from["column"] ? "straight" : "lane" }
    end

    def alongside_routing(from, to)
      leftward = to["column"] < from["column"]

      { "leaves" => leftward ? "left" : "right", "enters" => leftward ? "right" : "left",
        "route" => to["row"] == from["row"] ? "straight" : "detour" }
    end

    def palette
      @registry.step_types.reject(&:begins_here?).map do |step_type|
        { "type" => step_type.id.to_s, "label" => step_type.step_name,
          "fields" => step_type.settings.fields.transform_keys(&:to_s).transform_values(&:to_s),
          "labels" => step_type.settings.labels.transform_keys(&:to_s),
          "choices" => step_type.settings.choices.transform_keys(&:to_s),
          "records" => holdings_of(step_type),
          "record_labels" => step_type.settings.record_labels.to_h { |name, held| [ name.to_s, held.transform_keys(&:to_s) ] },
          "awaits_input" => step_type.awaits_input? }
      end
    end

    def holdings_of(step_type)
      step_type.settings.record_fields.to_h do |name, holds|
        [ name.to_s, holds.transform_keys(&:to_s).transform_values(&:to_s) ]
      end
    end

    def violations
      Validator.new(@document, registry: @registry).violations.map do |violation|
        { "node" => violation.node, "problem" => violation.problem.to_s, "detail" => violation.detail }
      end
    end

    def label_for(node)
      Name.of(node, @registry)
    end

    def choices_for(node)
      naming_steps(node).index_with { earlier_than(node) }.merge(drawn_by(node)).merge(named_outputs_by(node))
    end

    def named_outputs_by(node)
      step_type_for(node)&.settings&.outputs_of.to_h.to_h do |name, source|
        [ name.to_s, digest.outputs_of(node.config[source.to_s]) ]
      end
    end

    def drawn_by(node)
      step_type_for(node)&.settings&.drawn_from.to_h.to_h do |name, source|
        [ name.to_s, digest.values_of(step_named_by(node, source), node.config[source.to_s]) ]
      end
    end

    def step_named_by(node, source)
      node.config[step_type_for(node).settings.outputs_of[source].to_s]
    end

    def digest
      Digest.new(@document, registry: @registry)
    end

    def naming_steps(node)
      step_type_for(node)&.settings&.naming_steps.to_a.map(&:to_s)
    end

    def earlier_than(node)
      digest.preceding(node.id).map do |id|
        { "value" => id, "label" => label_for(@document.node(id)) }
      end
    end

    def ends_here?(node)
      step_type_for(node)&.ends_here? || false
    end

    def loose?(node)
      @document.entry.present? && @document.reachable.exclude?(node.id)
    end

    def begins_here?(node)
      step_type_for(node)&.begins_here? || false
    end

    def ports_for(node)
      digest.routing_values(node.id)
    end

    def step_type_for(node)
      @registry.fetch(node.type) if @registry.registered?(node.type)
    end
  end
end
