module EasyFlow
  class UnconnectedSteps
    def initialize(document, flow: nil, registry: EasyFlow.registry)
      @document = document
      @flow = flow
      @registry = registry
    end

    def ids
      @document.unconnected
    end

    def named
      ids.map { |id| { "id" => id, "label" => Name.of(@document.node(id), @registry), "name" => Name.shown(@document.node(id), @registry).tr("_", " ") } }
    end

    def accepted?(named_steps)
      Array(named_steps).map(&:to_s).sort == ids.map(&:to_s).sort
    end

    def objections
      Validator.new(staying, registry: @registry, flow: @flow).violations + readers
    end

    private

    def readers
      staying.nodes.select { |node| entries_naming(node).intersect?(ids) }
        .map { |node| Violation.new(node: node.id, problem: :reading_an_unconnected_step) }
    end

    def entries_naming(node)
      return [] unless @registry.registered?(node.type)

      @registry.fetch(node.type).settings.record_fields.flat_map do |list, holds|
        Array(node.config[list.to_s]).flat_map { |entry| entry.to_h.values_at(*holds.select { |_name, type| type == :previous_step }.keys.map(&:to_s)) }
      end
    end

    def staying
      @document.without(ids)
    end
  end
end
