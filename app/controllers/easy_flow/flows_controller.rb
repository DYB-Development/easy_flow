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
      @question = @guide.next_step(@answers, run: run, times: @progress.answered_at)
      @drawing = @guide.drawing_at(@answers, times: @progress.answered_at)
      flash.now[:alert] = @refused if @refused
      @waiting = waiting_on(@question)
      return render :step if @question

      render_completion
    end

    def update
      params[:back] ? go_back : record_submitted
      redirect_to run_location(run)
    end

    private

    def go_back
      guide = runner_for(running_definition)
      loop do
        before = progress.recorded
        progress.discard_last
        break if progress.recorded == before || !guide.fills_in_next?(progress.recorded)
      end
    end

    def runner_for(definition)
      QuestionRunner.new(definition, host: flow_host)
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
      @answered = @guide.state_on_path(@answers, times: @progress.answered_at)
      finished(@answered, @progress.finish(@answered))
    end

    def finished(_answers, _run)
      render :complete
    end

    def progress
      return @progress ||= Progress.for(run.flow, run: run) if run

      answers = submitted_answers
      @progress ||= Progress.for(flow, answers: answers, answered_at: submitted_times(answers), definition: running_definition)
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

    def submitted_times(answers)
      given = params.fetch(:answered_at, {}).permit(*answers.keys).to_h.symbolize_keys
      times = given.transform_values { |time| readable_time(time) }.compact
      asked = params[:asked].to_s.to_sym
      answers.key?(asked) && !times.key?(asked) ? times.merge(asked => Time.current) : times
    end

    def readable_time(time)
      Time.zone.parse(time.to_s)
    rescue ArgumentError
      nil
    end

    def one_answer_back(answers)
      answered = @guide.state_on_path(answers)
      loop do
        answered = answered.except(answered.keys.last)
        break if answered.empty? || !@guide.fills_in_next?(answered)
      end
      answered
    end

    def record_submitted
      id, value = params.fetch(:answers, {}).permit(*asked, **asked.index_with { [] }).to_h.first
      id ||= params[:asked].presence_in(asked)
      return if id.nil?

      problem = answer_problem(runner_for(run.pinned_definition).step(id.to_s), value)
      return flash[:alert] = problem if problem

      progress.record(id, recorded(value))
    end

    def recorded(value)
      return value.compact_blank.map { |each| recorded(each) } if value.is_a?(Array)
      return EasyFlow.keep_file(value) if value.respond_to?(:original_filename)

      value.to_s
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
