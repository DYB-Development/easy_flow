module EasyFlow
  module DataStep
    extend ActiveSupport::Concern
    include Inputs

    included do
      names_by :data
      needs_a_saved_run "Data can only be read or written in a flow that saves its runs."

      setting(:values, type: :list, label: "Values it reports") { setting :name, type: :string, required: true }
      outputs_named_by :values

      output :result, values: %w[passed failed]
      output :reason
      output :answer
    end

    def process(node, state, run: nil)
      raise ArgumentError, "#{node.config["data"]} is not offered by this step" unless self.class.step_type.settings.choices[:data].include?(node.config["data"])

      answer = ActiveRecord::Base.transaction(requires_new: true) do
        EasyFlow.data_source.carry_out(node.config["data"], Inputs.values_of(node, state, run: run))
      end.as_json
      (answer.is_a?(Hash) ? answer : { "answer" => answer }).merge("result" => "passed")
    rescue => error
      { "result" => "failed", "reason" => error.message }
    end

    def route(node, state)
      state.dig(node.id, "result")
    end
  end
end
