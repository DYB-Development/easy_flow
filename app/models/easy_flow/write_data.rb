module EasyFlow
  class WriteData
    include Step

    step_name "Write data"

    setting :data, type: :select, label: "What to write", required: true, options: -> { EasyFlow.data_source&.writes.to_a }
  end
end
