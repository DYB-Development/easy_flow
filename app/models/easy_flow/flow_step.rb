module EasyFlow
  class FlowStep
    include Step

    step_name "Flow"

    setting :flow, type: :flow
    setting :version, type: :integer
  end
end
