module EasyFlow
  module Inputs
    extend ActiveSupport::Concern

    included do
      setting :inputs, type: :list do
        setting :name, type: :string, required: true
        setting :value, type: :string
        setting :step, type: :previous_step, label: "Earlier step"
        setting :output, outputs_of: :step, label: "Earlier step's output"
      end
    end

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
