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
      @question = @guide.next_step(@answers, run: run)
      @drawing = @guide.drawing_at(@answers)
      flash.now[:alert] = @refused if @refused
      @waiting = waiting_on(@question)
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
      found = Run.where(flow: hosted_flows).find(params[:id])

      Admission.of_run(found, permitted: permitted?(found.flow))
    end

    def flow
      @stored_flow ||= admit(hosted_flows.find_by(slug: params[:slug]))
    end

    def flowing_definition(flow)
      flow.live_definition
    end

    def submitted_answers
      given = params.fetch(:answers, {})
      keys = given.keys.select { |key| @guide.step(key) }
      answers = given.permit(*keys, **keys.index_with { [] }).to_h.symbolize_keys.transform_values { |value| value.is_a?(Array) ? value.compact_blank : value }
      return one_answer_back(answers) if params[:back].present?

      key = params[:asked].to_s.to_sym
      asked = @guide.step(key)
      return answers unless asked

      answer = answers.fetch(key, "")
      @refused = answer_problem(asked, answer)
      @refused ? answers.except(key) : answers.merge(key => answer)
    end

    def one_answer_back(answers)
      answered = @guide.state_on_path(answers)
      answered.except(answered.keys.last)
    end

    def record_submitted
      id, value = params.fetch(:answers, {}).permit(*asked, **asked.index_with { [] }).to_h.first
      id ||= params[:asked].presence_in(asked)
      return if id.nil?

      problem = answer_problem(runner_for(run.pinned_definition).step(id.to_s), value)
      return flash[:alert] = problem if problem

      progress.record(id, value.is_a?(Array) ? value.compact_blank : value.to_s)
    end

    def waiting_on(step)
      return unless step.respond_to?(:type) && EasyFlow.registry.registered?(step.type)

      step_type = EasyFlow.registry.fetch(step.type)
      step_type.name_of(step).presence || step_type.step_name if step_type.waits?
    end

    def answer_problem(step, answer)
      return unless step && EasyFlow.registry.registered?(step.type)

      EasyFlow.registry.fetch(step.type).answer_problem(step, answer)
    end

    def asked
      guide = runner_for(run.pinned_definition)
      guide.steps.map(&:id) | [ guide.next_step(run.recorded)&.id ].compact
    end
  end
end
