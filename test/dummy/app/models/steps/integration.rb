module Steps
  class Integration
    include EasyFlow::Step

    step_name "Integration"

    setting :effect, type: :select, options: %w[pure keyed]
    setting :service, type: :string, optional: true
    setting :compensate, type: :string, optional: true

    summarizes_by do |node|
      [ node.config["effect"], node.config["service"], node.config["compensate"].presence && "compensate: #{node.config['compensate']}" ].compact_blank.join(" · ")
    end
  end
end
