class CodedFlowsController < EasyFlow::FlowsController
  hosted_by :dummy
  routed_by :coded

  private

  def run_address(run) = "run-#{run.id}"

  def find_run(runs, address) = runs.find(address.delete_prefix("run-"))
end
