class HostFlowsController < EasyFlow::FlowsController
  class Runner < EasyFlow::QuestionRunner
    def headline = "Chosen by the host"
  end

  private

  def runner_for(definition) = Runner.new(definition)
end
