module EasyFlow
  class Runner
    def initialize(document, registry: EasyFlow.registry)
      @document = document.to_h
      @registry = registry
      @digest = Digest.new(Document.new(@document, registry: registry), registry: registry)
    end

    def slug
      @document["slug"]
    end

    def headline
      @document["headline"]
    end

    def steps
      @digest.steps
    end

    def step(id)
      @digest.step(id.to_s)
    end

    def next_step(state)
      shown(@digest.next_step(named(state)))
    end

    def run(progress)
      while (node = @digest.next_step(named(progress.recorded))) && acts?(node)
        progress.record(node.id, @registry.fetch(node.type).process(node, named(progress.recorded)))
      end
    end

    def drawing_at(state)
      Drawing.of(@digest.next_step(named(state)), @registry)
    end

    def state_on_path(state)
      @digest.state_on_path(named(state)).symbolize_keys
    end

    def steps_on_path(state)
      state_on_path(state).keys.map { |id| shown(@digest.step(id.to_s)) }
    end

    private

    def acts?(node)
      @registry.registered?(node.type) && @registry.fetch(node.type).acts?
    end

    def shown(node)
      return node unless node && @registry.registered?(node.type)

      @registry.fetch(node.type).display_of(node) || node
    end

    def named(state)
      state.transform_keys(&:to_s)
    end
  end
end
