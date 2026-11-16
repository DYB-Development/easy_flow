module Steps
  class Agent
    include EasyFlow::Step

    step_name "Agent"

    setting :agent, type: :string
    setting :release, type: :string
    setting :gate, type: :string, optional: true
    setting :alias, type: :radio_cards, options: [
      { value: "prod", label: "prod → v22", hint: "p 0.84 · n 1,920" },
      { value: "candidate", label: "candidate → v23", hint: "p 0.87 · n 240" }
    ]

    shows_values("Inputs") do |_node|
      { "brief" => "load_brief.out.brief", "voice" => "brand_voice.out.doc", "angle" => "$item.angle", "findings" => "copy_reviewer.out.findings ?" }
    end

    shows_code("Schemas") do |_node|
      { "input_schema" => "{brief: Brief, voice: string, angle: string, findings?: Finding[]}",
        "output_schema → copy_block v3" => "{headline: string≤60, body: string≤400, cta: string≤30, meta: {tone, words}}" }
    end

    links_to do |node|
      [ { label: "Open agent", address: "/agents/#{node.config['agent']}" }, { label: "Fixtures (4)", address: "/agents/#{node.config['agent']}/fixtures" } ]
    end

    summarizes_by { |node| [ [ node.config["agent"], node.config["release"] ].join(node.config["release"].to_s.start_with?("v") ? " " : "@"), node.config["gate"] ].compact_blank.join(" · ") }
  end
end
