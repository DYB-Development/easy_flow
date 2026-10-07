module EasyFlow
  class AdvanceParentJob < ActiveJob::Base
    def perform(run)
      run.advance
    end
  end
end
