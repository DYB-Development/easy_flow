module EasyFlow
  class AdvanceParentJob < ActiveJob::Base
    def perform(run, step)
      raise InnerFlowError, "Nothing was recorded at the Flow step #{step}, so its run cannot move on" unless run.recorded.key?(step.to_sym)

      run.advance
    end
  end
end
