module EasyFlow
  class Start
    include Step

    step_name "Start"

    begins_here

    names_by { |_node| "Start" }
  end
end
