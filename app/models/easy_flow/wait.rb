module EasyFlow
  class Wait
    include Step

    step_name "Wait"

    def self.held_until(node, times)
      from = times[node.config["step"]]
      return next_time_of_day(from, node.config["time_of_day"]) if node.config["time_of_day"].present?

      from + node.config["minutes"].to_i.minutes
    end

    def self.next_time_of_day(from, time_of_day)
      hour, minute = time_of_day.split(":").map(&:to_i)
      from.in_time_zone.tomorrow.change(hour: hour, min: minute)
    end
  end
end
