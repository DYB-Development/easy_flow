module EasyFlow
  class StepType
    def self.define(id, &declaration)
      Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
    end

    attr_reader :id, :step_name, :settings, :naming_field, :naming, :outputs, :drawn_by

    def initialize(id:, step_name:, settings:, awaits_input:, behaviour:, routing:,
      ends_here: false, begins_here: false, starts_a_flow: false, flow_chooser: nil, run_chooser: nil, display: nil, drawn_by: nil,
      naming_field: nil, naming: nil, outputs: [], outputs_named_by: nil, answer_check: nil, answer_labelling: nil, readiness: nil)
      @id = id
      @step_name = step_name
      @settings = settings
      @awaits_input = awaits_input
      @ends_here = ends_here
      @begins_here = begins_here
      @starts_a_flow = starts_a_flow
      @flow_chooser = flow_chooser
      @run_chooser = run_chooser
      @behaviour = behaviour
      @routing = routing
      @display = display
      @drawn_by = drawn_by
      @naming_field = naming_field
      @naming = naming
      @outputs = outputs
      @outputs_named_by = outputs_named_by
      @answer_check = answer_check
      @answer_labelling = answer_labelling
      @readiness = readiness
    end

    def display_of(node, run = nil)
      return unless @display

      @display.arity == 1 ? @display.call(node) : @display.call(node, run)
    end

    def process(node, state)
      @behaviour&.call(node, state)
    end

    def route(node, state)
      @routing&.call(node, state)
    end

    def answer_problem(node, value)
      @answer_check&.call(node, value)
    end

    def answer_label(node, value)
      @answer_labelling&.call(node, value)
    end

    def waits?
      @readiness.present?
    end

    def ready?(node, state)
      @readiness.call(node, state)
    end

    def name_of(node)
      @naming&.call(node).presence || node.config[naming_field.to_s].presence || worked_out_flow_name(node)
    end

    def acts?
      @behaviour.present?
    end

    def routes?
      @routing.present?
    end

    def outputs_for(node)
      outputs + named_outputs(node)
    end

    def values_of(name, node)
      outputs.find { |output| output.name.to_s == name.to_s }&.values_for(node).to_a
    end

    def awaits_input?
      @awaits_input
    end

    def ends_here?
      @ends_here
    end

    def begins_here?
      @begins_here
    end

    def starts_a_flow?
      @starts_a_flow
    end

    def chooses_flow_from_run?
      !@run_chooser.nil?
    end

    def flow_chosen_from_run(node, run)
      @run_chooser&.call(node, run)
    end

    def flow_chosen_by(node)
      @flow_chooser&.call(node)
    end

    def worked_out_flow_name(node)
      chosen = flow_chosen_by(node)
      ChosenFlow.worked_out(chosen).name if chosen
    end

    private

    def named_outputs(node)
      return [] unless @outputs_named_by

      Array(node.config[@outputs_named_by.to_s]).filter_map { |entry| entry["name"].presence }.map { |name| Output.new(name: name) }
    end
  end
end
