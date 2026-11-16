module Steps
  class Agent
    include EasyFlow::Step

    step_name "Agent"

    setting :agent, type: :string
    setting :release, type: :string
    setting :gate, type: :string, optional: true

    summarizes_by { |node| [ [ node.config["agent"], node.config["release"] ].join(node.config["release"].to_s.start_with?("v") ? " " : "@"), node.config["gate"] ].compact_blank.join(" · ") }
  end
end
