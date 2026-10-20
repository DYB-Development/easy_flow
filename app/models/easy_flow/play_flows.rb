module EasyFlow
  class PlayFlows
    include Step

    step_name "Play flows"

    setting :flows, type: :flows

    displays_by { |node, run| Asked.new(id: node.id.to_sym, text: node.config["question"], choices: PlayFlows.offered(node, run)) }

    def self.offered(node, run)
      listed = Array(node.config["flows"]) - played(node, run)
      Definition.where(id: listed).sort_by { |flow| listed.index(flow.id.to_s) }.map { |flow| Choice.new(value: flow.id.to_s, label: flow.title) }
    end

    def self.played(node, run)
      step = node.id.to_s.split("@").first
      run.inner_runs.where(parent_step: step).or(run.inner_runs.where("parent_step LIKE ?", "#{Run.sanitize_sql_like(step)}@%")).pluck(:flow_id).map(&:to_s)
    end
  end
end
