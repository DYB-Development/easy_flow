module EasyFlow
  module CompletedAt
    OUTPUTS = {
      "completed_hour" => "Hour completed",
      "completed_weekday" => "Weekday completed",
      "completed_minute" => "Minutes since 1970 when completed"
    }.freeze

    READERS = {
      "completed_hour" => ->(time) { time.hour },
      "completed_weekday" => ->(time) { time.to_date.cwday },
      "completed_minute" => ->(time) { time.to_i / 60 }
    }.freeze

    def self.read(output, time)
      READERS.fetch(output).call(time.in_time_zone)
    end

    def self.value_of(state, times, step, output)
      return times[step] && read(output, times[step]) if OUTPUTS.key?(output)

      given = state[step]
      given.is_a?(Hash) ? given[output] : given
    end

    def self.latest(times)
      times.sort_by { |key, _time| key.to_s.split("@").last.to_i }.to_h { |key, time| [ key.to_s.split("@").first, time ] }
    end

    def self.outputs
      OUTPUTS.map { |value, label| { "value" => value, "label" => label } }
    end
  end
end
