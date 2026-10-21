module EasyFlow
  class PlayFlows
    include Step

    step_name "Play flows"

    setting :question, type: :string
    setting :flows, type: :flows, required: true

    names_by :question
    awaits_input

    plays_the_picked_flow

    comes_back_while { |node, state| PlayFlows.visits(node, state) < PlayFlows.playable(node).size }

    displays_by { |node, run| Asked.new(id: node.id.to_sym, text: node.config["question"], choices: PlayFlows.offered(node, run)) }

    def self.visits(node, state)
      state.keys.count { |key| key.to_s == node.id || key.to_s.start_with?("#{node.id}@") }
    end

    def self.playable(node)
      Definition.where(id: Array(node.config["flows"])).select(&:live_version)
    end

    def self.offered(node, run)
      return [] unless run

      listed = Array(node.config["flows"]) - played(node, run)
      Definition.where(id: listed).select { |flow| run.flow.reaches?(flow) }.sort_by { |flow| listed.index(flow.id.to_s) }.map { |flow| Choice.new(value: flow.id.to_s, label: flow.title) }
    end

    def self.played(node, run)
      step = node.id.to_s.split("@").first
      run.inner_runs.where(parent_step: step).or(run.inner_runs.where("parent_step LIKE ?", "#{Run.sanitize_sql_like(step)}@%")).pluck(:flow_id).map(&:to_s)
    end
  end
end
