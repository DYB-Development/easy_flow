class CodedFlowsController < EasyFlow::FlowsController
  hosted_by :dummy
  routed_by :coded

  private

  def run_address(run) = "run-#{run.id}"
end
