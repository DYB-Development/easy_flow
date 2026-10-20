module EasyFlow
  class PlayFlows
    include Step

    step_name "Play flows"

    setting :flows, type: :flows

    displays_by { |node, run| Asked.new(id: node.id.to_sym, text: node.config["question"], choices: PlayFlows.offered(node, run)) }

    def self.offered(node, _run)
      listed = Array(node.config["flows"])
      Definition.where(id: listed).sort_by { |flow| listed.index(flow.id.to_s) }.map { |flow| Choice.new(value: flow.id.to_s, label: flow.title) }
    end
  end
end
