module EasyFlow
  class ReadData
    include Step

    step_name "Read data"

    setting :data, type: :select, label: "What to read", required: true, options: -> { EasyFlow.data_source&.reads.to_a }

    include DataStep
  end
end
