module EasyFlow
  module Progress
    def self.for(flow, run: nil, answers: {}, definition: nil)
      return Kept.new(run) if run

      Loose.new(flow, answers, definition)
    end
  end
end
