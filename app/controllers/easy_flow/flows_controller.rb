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
      easy_flow.run_path(run)
    end

    def start_run(flow)
      Run.start(flow)
    end

    def flow_start_path(slug)
      easy_flow.flow_path(slug)
    end

    def flow_step_path(slug)
      easy_flow.flow_step_path(slug)
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
      @progress.finish(@answered)
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
      found = Run.find(params[:id])

      Admission.of_run(found, permitted: permitted?(found.flow))
    end

    def flow
      @stored_flow ||= admit(Definition.find_by(slug: params[:slug]))
    end

    def flowing_definition(flow)
      flow.live_definition
    end

    def submitted_answers
      params.fetch(:answers, {}).permit(*@guide.steps.map(&:id)).to_h.symbolize_keys
    end

    def record_submitted
      id, value = params.fetch(:answers, {}).permit(*asked).to_h.first
      progress.record(id, value)
    end

    def asked
      runner_for(run.pinned_definition).steps.map(&:id)
    end
  end
end
