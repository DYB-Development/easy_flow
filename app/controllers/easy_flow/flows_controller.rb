module EasyFlow
  class FlowsController < ApplicationController
    helper_method :flow_start_path, :flow_step_path, :previewing?, :step_form, :carries_answers?

    def show
      @flow = flow
    end

    def start
      redirect_to run_location(start_run(flow))
    end

    def step
      @guide = runner_for(running_definition)
      @progress = progress
      @guide.run(@progress)
      @answers = @progress.recorded
      @question = @guide.next_step(@answers)
      @drawing = @guide.drawing_at(@answers)
      flash.now[:alert] = @refused if @refused
      return render :step if @question

      render_completion
    end

    def update
      params[:back] ? progress.discard_last : record_submitted
      redirect_to run_location(run)
    end

    private

    def runner_for(definition)
      QuestionRunner.new(definition)
    end

    def run_location(run)
      flow_routes.run_path(run)
    end

    def start_run(flow)
      Run.start(flow)
    end

    def flow_start_path(slug)
      flow_routes.flow_path(slug)
    end

    def flow_step_path(slug)
      flow_routes.flow_step_path(slug)
    end

    def previewing?
      false
    end

    def step_form
      return { url: run_location(run), method: :patch } if run

      { url: flow_step_path(@guide.slug), method: :get }
    end

    def carries_answers?
      run.nil?
    end

    def render_completion
      @answered = @guide.state_on_path(@answers)
      finished(@answered, @progress.finish(@answered))
    end

    def finished(_answers, _run)
      render :complete
    end

    def progress
      return @progress ||= Progress.for(run.flow, run: run) if run

      @progress ||= Progress.for(flow, answers: submitted_answers, definition: running_definition)
    end

    def running_definition
      @running_definition ||= run ? run.pinned_definition : flowing_definition(flow)
    end

    def run
      return unless params[:id]

      @run ||= admitted_run
    end

    def admitted_run
      found = Run.where(flow: flow_host.flows).find(params[:id])

      Admission.of_run(found, permitted: permitted?(found.flow))
    end

    def flow
      @stored_flow ||= admit(flow_host.flows.find_by(slug: params[:slug]))
    end

    def flowing_definition(flow)
      flow.live_definition
    end

    def submitted_answers
      answers = params.fetch(:answers, {}).permit(*@guide.steps.map(&:id)).to_h.symbolize_keys
      asked = @guide.step(params[:asked].to_s)
      return answers unless asked

      answer = answers.fetch(asked.id.to_sym, "")
      @refused = answer_problem(asked, answer)
      @refused ? answers.except(asked.id.to_sym) : answers.merge(asked.id.to_sym => answer)
    end

    def record_submitted
      id, value = params.fetch(:answers, {}).permit(*asked).to_h.first
      id ||= params[:asked].presence_in(asked)
      return if id.nil?

      problem = answer_problem(runner_for(run.pinned_definition).step(id.to_s), value)
      return flash[:alert] = problem if problem

      progress.record(id, value.to_s)
    end

    def answer_problem(step, answer)
      return unless step && EasyFlow.registry.registered?(step.type)

      EasyFlow.registry.fetch(step.type).answer_problem(step, answer)
    end

    def asked
      runner_for(run.pinned_definition).steps.map(&:id)
    end
  end
end
