module EasyFlow
  class Wait
    include Step

    step_name "Wait"

    def self.held_until(node, times)
      times[node.config["step"]] + node.config["minutes"].to_i.minutes
    end
  end
end
