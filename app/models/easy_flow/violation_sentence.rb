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

    def past_the_end(violation)
      "#{step(violation.node)} ends the flow, but a connection leaves it. Remove that connection."
    end

    def unfollowed_path(violation)
      "The connection from #{step(violation.node)} to #{step(violation.detail)} is never followed, because #{step(violation.node)} only follows its first connection. Remove the connection to #{step(violation.detail)}."
    end

    def missing_setting(violation)
      "#{step(violation.node)} needs a value for #{setting_label(violation)}. Set it in the step's settings."
    end

    def setting_label(violation)
      @registry.fetch(@document.node(violation.node).type).settings.labels[violation.detail.to_sym]
    end
  end
end
