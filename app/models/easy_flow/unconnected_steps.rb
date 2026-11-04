module EasyFlow
  class UnconnectedSteps
    def initialize(document, flow: nil, registry: EasyFlow.registry)
      @document = document
      @flow = flow
      @registry = registry
    end

    def objections
      Validator.new(staying, registry: @registry, flow: @flow).violations
    end

    private

    def staying
      @document.without(@document.unconnected)
    end
  end
end
