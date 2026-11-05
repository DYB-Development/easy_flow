module EasyFlow
  class ViolationSentence
    def initialize(document, registry: EasyFlow.registry)
      @document = document
      @registry = registry
    end

    def of(violation)
      send(violation.problem, violation).tr("_", " ")
    end

    private

    def step(id)
      Name.shown(@document.node(id), @registry)
    end

    def dead_end(violation)
      "#{step(violation.node)} leads nowhere. Connect it to the step that should come next."
    end

    def unrouted_value(violation)
      "#{violation.detail.to_s.upcase_first} on #{step(violation.node)} leads nowhere. Connect it to the step that should come next."
    end

    def unreachable(violation)
      "#{step(violation.node)} is not connected to the flow. Connect a step to it, or delete it."
    end
  end
end
