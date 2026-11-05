module EasyFlow
  module Inputs
    extend ActiveSupport::Concern

    included do
      setting :inputs, type: :list do
        setting :name, type: :string, required: true
        setting :value, type: :string
        setting :step, type: :previous_step, label: "Earlier step"
        setting :output, outputs_of: :step, label: "Earlier step's output"
        setting :from_run_owner, type: :boolean, label: "The run's owner"
      end
    end

    def self.values_of(node, state, run: nil)
      Array(node.config["inputs"]).to_h { |input| [ input["name"], value_of(input, state, run) ] }
    end

    def self.value_of(input, state, run)
      return run&.owner_id if input["from_run_owner"]

      input["step"].present? ? latest_output(input, state, run) : input["value"]
    end
    private_class_method :value_of

    def self.latest_output(input, state, run)
      latest_visit = state.keys.select { |key| key.split("@").first == input["step"] }.max_by { |key| key.split("@")[1].to_i }
      return if unreported?(input, state[latest_visit], run)

      CompletedAt.value_of(state, {}, latest_visit, input["output"])
    end
    private_class_method :latest_output

    def self.unreported?(input, recorded, run)
      !recorded.is_a?(Hash) && !run.digest.plain_value_is?(input["step"], input["output"])
    end
    private_class_method :unreported?
  end
end
