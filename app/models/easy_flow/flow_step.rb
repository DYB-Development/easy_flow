module EasyFlow
  class FlowStep
    include Step

    step_name "Flow"

    setting :version, type: :integer
  end
end
