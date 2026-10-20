module EasyFlow
  class PlayFlows
    include Step

    step_name "Play flows"

    setting :flows, type: :flows
  end
end
