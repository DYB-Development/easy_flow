module EasyFlow
  module Inputs
    def self.values_of(node, state)
      Array(node.config["inputs"]).to_h { |input| [ input["name"], input["step"].present? ? latest_output(input, state) : input["value"] ] }
    end

    def self.latest_output(input, state)
      latest_visit = state.keys.select { |key| key.split("@").first == input["step"] }.max_by { |key| key.split("@")[1].to_i }
      CompletedAt.value_of(state, {}, latest_visit, input["output"])
    end
    private_class_method :latest_output
  end
end
