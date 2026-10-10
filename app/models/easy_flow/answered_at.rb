module EasyFlow
  module AnsweredAt
    OUTPUTS = {
      "answered_hour" => "Hour answered",
      "answered_weekday" => "Weekday answered",
      "answered_minute" => "Minutes since 1970 when answered"
    }.freeze

    READERS = {
      "answered_hour" => ->(time) { time.hour },
      "answered_weekday" => ->(time) { time.to_date.cwday },
      "answered_minute" => ->(time) { time.to_i / 60 }
    }.freeze

    def self.read(output, time)
      READERS.fetch(output).call(time.in_time_zone)
    end

    def self.outputs
      OUTPUTS.map { |value, label| { "value" => value, "label" => label } }
    end
  end
end
