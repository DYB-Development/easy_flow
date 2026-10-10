module EasyFlow
  module Progress
    def self.for(flow, run: nil, answers: {}, completed_at: {}, definition: nil)
      return Kept.new(run) if run

      Loose.new(flow, answers, definition, completed_at)
    end
  end
end
