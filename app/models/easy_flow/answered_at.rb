module EasyFlow
  module AnsweredAt
    OUTPUTS = {
      "answered_hour" => "Hour answered",
      "answered_weekday" => "Weekday answered",
      "answered_minute" => "Minutes since 1970 when answered"
    }.freeze

    def self.outputs
      OUTPUTS.map { |value, label| { "value" => value, "label" => label } }
    end
  end
end
