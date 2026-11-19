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
        setting :current_item, type: :boolean, label: "The current item"
      end
    end

    def self.values_of(node, state, run: nil)
      Array(node.config["inputs"]).to_h { |input| [ input["name"], value_of(node, input, state, run) ] }
    end

    def self.value_of(node, input, state, run)
      return run&.owner_id if input["from_run_owner"]
      return run&.digest&.item_value(node.id, state) if input["current_item"]

      input["step"].present? ? latest_output(node, input, state, run) : input["value"]
    end
    private_class_method :value_of

    def self.latest_output(node, input, state, run)
      latest_visit = latest_visit_of(input["step"], VisitKey.parse(node.id).item, state)
      return if unreported?(input, state[latest_visit], run)

      CompletedAt.value_of(state, {}, latest_visit, input["output"])
    end
    private_class_method :latest_output

    def self.latest_visit_of(step, item, state)
      visits = state.keys.to_h { |key| [ key, VisitKey.parse(key) ] }.select { |_key, visit| visit.step == step }
      same_item = visits.select { |_key, visit| visit.item == item }
      (same_item.presence || visits.reject { |_key, visit| visit.item }).max_by { |_key, visit| visit.visit }&.first
    end
    private_class_method :latest_visit_of

    def self.unreported?(input, recorded, run)
      run && input["output"].present? && !recorded.is_a?(Hash) && !run.digest.plain_value_is?(input["step"], input["output"])
    end
    private_class_method :unreported?
  end
end
