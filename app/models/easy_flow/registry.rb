module EasyFlow
  class Registry
    def initialize
      @step_types = {}
    end

    def register(step_type)
      @step_types[step_type.id.to_sym] = step_type
    end

    def fetch(id)
      @step_types.fetch(id.to_sym) { raise UnknownStepType, "no step type registered as #{id}" }
    end

    def registered?(id)
      id.present? && @step_types.key?(id.to_sym)
    end

    def step_types
      @step_types.values
    end
  end
end
