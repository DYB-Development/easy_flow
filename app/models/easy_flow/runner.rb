module EasyFlow
  class Runner
    def initialize(document, registry: EasyFlow.registry, host: nil)
      @document = document.to_h
      @registry = registry
      @host = host
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

    def next_step(state, run: nil)
      shown(@digest.next_step(named(state)), run)
    end

    def run(progress)
      while (node = @digest.next_step(named(progress.recorded))) && goes_on?(node, named(progress.recorded))
        progress.record(node.id, result_of(@digest.step(node.id), named(progress.recorded)))
      end
      progress.start_inner(node) if node && starts_a_flow?(node)
      progress.ended unless node
    end

    def drawing_at(state)
      Drawing.of(@digest.next_step(named(state)), @registry)
    end

    def state_on_path(state)
      @digest.state_on_path(named(state)).symbolize_keys
    end

    def questions_left(state)
      @digest.questions_left(named(state))
    end

    def steps_on_path(state)
      state_on_path(state).keys.map { |id| shown(@digest.step(id.to_s)) }
    end

    private

    def starts_a_flow?(node)
      @registry.registered?(node.type) && @registry.fetch(node.type).starts_a_flow?
    end

    def acts?(node)
      @registry.registered?(node.type) && @registry.fetch(node.type).acts?
    end

    def goes_on?(node, state)
      acts?(node) || ready?(node, state) || decided?(node, state)
    end

    def allowed(node, state)
      @host&.answers_allowed(node, state.symbolize_keys)
    end

    def decided?(node, state)
      choices = allowed(node, state)
      !choices.nil? && choices.size <= 1
    end

    def ready?(node, state)
      @registry.registered?(node.type) && @registry.fetch(node.type).waits? && @registry.fetch(node.type).ready?(node, state)
    end

    def result_of(node, state)
      return allowed(node, state).first.to_s if decided?(node, state)

      acts?(node) ? @registry.fetch(node.type).process(node, state) : true
    end

    def shown(node, run = nil)
      return node unless node && @registry.registered?(node.type)

      @registry.fetch(node.type).display_of(node, run) || node
    end

    def named(state)
      state.transform_keys(&:to_s)
    end
  end
end
