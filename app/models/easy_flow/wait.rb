module EasyFlow
  class Wait
    include Step

    step_name "Wait"

    setting :step, type: :previous_step, label: "Counting from", required: true
    setting :minutes, type: :integer, label: "Minutes after it"
    setting :time_of_day, type: :string, label: "Next time of day after it, as HH:MM"
    setting :date, type: :string, label: "Date, as YYYY-MM-DD"

    names_by { |node| "#{node.config["minutes"]} minutes after #{node.config["step"]}" }

    waits_until { |node, _state, times| Wait.held_until(node, times)&.then { |held| held <= Time.current } || false }

    def self.held_until(node, times)
      from = times[node.config["step"]]
      return Time.zone.parse(node.config["date"]) if node.config["date"].present?
      return if from.nil?
      return next_time_of_day(from, node.config["time_of_day"]) if node.config["time_of_day"].present?

      from + node.config["minutes"].to_i.minutes
    end

    def self.next_time_of_day(from, time_of_day)
      hour, minute = time_of_day.split(":").map(&:to_i)
      same_day = from.in_time_zone.change(hour: hour, min: minute)
      same_day > from ? same_day : same_day.tomorrow
    end
  end
end
