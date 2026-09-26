module EasyFlow
  class StepType
    def self.define(id, &declaration)
      Declaration.new(id).tap { |decl| decl.instance_eval(&declaration) }.to_step_type
    end

    attr_reader :id, :step_name, :settings, :naming_field, :naming, :outputs, :drawn_by

    def initialize(id:, step_name:, settings:, awaits_input:, behaviour:, routing:,
      ends_here: false, begins_here: false, display: nil, drawn_by: nil,
      naming_field: nil, naming: nil, outputs: [], answer_check: nil)
      @id = id
      @step_name = step_name
      @settings = settings
      @awaits_input = awaits_input
      @ends_here = ends_here
      @begins_here = begins_here
      @behaviour = behaviour
      @routing = routing
      @display = display
      @drawn_by = drawn_by
      @naming_field = naming_field
      @naming = naming
      @outputs = outputs
      @answer_check = answer_check
    end

    def display_of(node)
      @display&.call(node)
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

    def name_of(node)
      @naming&.call(node).presence || node.config[naming_field.to_s].presence
    end

    def acts?
      @behaviour.present?
    end

    def routes?
      @routing.present?
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
  end
end
