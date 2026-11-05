module EasyFlow
  class ViolationSentence
    def initialize(document, registry: EasyFlow.registry)
      @document = document
      @registry = registry
    end

    def of(violation)
      send(violation.problem, violation)
    end

    private

    def step(id)
      Name.shown(@document.node(id), @registry)
    end

    def dead_end(violation)
      "#{step(violation.node)} leads nowhere. Connect it to the step that should come next."
    end
  end
end
