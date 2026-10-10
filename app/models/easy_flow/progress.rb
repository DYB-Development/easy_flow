module EasyFlow
  module Progress
    def self.for(flow, run: nil, answers: {}, answered_at: {}, definition: nil)
      return Kept.new(run) if run

      Loose.new(flow, answers, definition, answered_at)
    end
  end
end
