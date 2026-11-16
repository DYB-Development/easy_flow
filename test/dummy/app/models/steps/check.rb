module Steps
  class Check
    include EasyFlow::Step

    step_name "Check"

    setting(:validators, type: :list) { setting :rule, type: :string }

    summarizes_by { |node| "#{Array(node.config['validators']).size} validators" }
  end
end
