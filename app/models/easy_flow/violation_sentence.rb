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
      settings = @registry.fetch(@document.node(violation.node).type).settings
      list, position, name = violation.detail.split(" ", 3)
      return settings.labels[list.to_sym] unless name

      "#{settings.record_labels[list.to_sym][name.to_sym]} in #{settings.labels[list.to_sym]} entry #{position}"
    end

    def missing_value(violation)
      "#{step(violation.node)} picks the answer #{violation.detail}, which the earlier step no longer offers. Pick another answer in the step's settings."
    end

    def unmet_requirement(violation)
      return "#{step(violation.node)} reads a step that no longer exists. Pick another step in its settings." unless @document.node(violation.detail)

      "#{step(violation.node)} reads #{step(violation.detail)}, which not every path to it goes through. Move #{step(violation.detail)} ahead of it on every path, or pick another step in its settings."
    end

    def missing_edge_target(violation)
      "A connection from #{step(violation.node)} leads to a step that does not exist. Remove it in the flow's definition."
    end

    def missing_edge_source(violation)
      "A connection into #{step(violation.node)} comes from a step that does not exist. Remove it in the flow's definition."
    end

    def duplicate_id(violation)
      "#{step(violation.node)} has the same id as another step. Change one of the ids in the flow's definition."
    end

    def reserved_id(violation)
      "#{step(violation.node)} has an id with an @ in it, which a flow cannot use. Change the id in the flow's definition."
    end

    def no_beginning(_violation)
      "This flow has no start step. Add one in the flow's definition."
    end

    def many_beginnings(violation)
      "#{step(violation.node)} is a second start step. Delete it."
    end

    def before_the_beginning(violation)
      "A connection leads into #{step(violation.node)}, where the flow starts. Remove that connection."
    end

    def missing_flow(violation)
      "#{step(violation.node)} is missing a flow. Pick the flow in its settings."
    end

    def unrunnable_version(violation)
      "#{step(violation.node)} names a version that cannot run. Pick a published version in its settings."
    end

    def owned_by_another_owner(violation)
      "#{step(violation.node)} names a flow that belongs to another owner. Pick another flow in its settings."
    end
  end
end
