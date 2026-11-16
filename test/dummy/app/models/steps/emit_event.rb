module Steps
  class EmitEvent
    include EasyFlow::Step

    step_name "Emit event"

    setting :event, type: :string, required: true

    summarizes_by { |node| node.config["event"] }
  end
end
