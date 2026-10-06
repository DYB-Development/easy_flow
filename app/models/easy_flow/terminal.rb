module EasyFlow
  class Terminal
    include Step

    step_name "End"

    ends_here

    setting :output, type: :string

    names_by { |_node| "End" }
  end
end
