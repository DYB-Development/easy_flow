class HostFlowsController < EasyFlow::FlowsController
  hosted_by :dummy
  routed_by :host

  class Runner < EasyFlow::QuestionRunner
    def headline = "Chosen by the host"
  end

  private

  def runner_for(definition) = Runner.new(definition)

  def run_location(run) = main_app.host_run_path(run)

  def start_run(flow) = super.tap { |run| run.update!(label: "Started by the host") }

  def finished(answers, _run) = render(plain: "The host takes it from here: #{answers[:annual_fee]}")
end
