module EasyFlow
  module Inputs
    def self.values_of(node, state)
      Array(node.config["inputs"]).to_h { |input| [ input["name"], input["step"].present? ? CompletedAt.value_of(state, {}, input["step"], input["output"]) : input["value"] ] }
    end
  end
end
