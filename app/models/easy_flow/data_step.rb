module EasyFlow
  module DataStep
    extend ActiveSupport::Concern
    include Inputs

    def process(node, state)
      raise ArgumentError, "#{node.config["data"]} is not offered by this step" unless self.class.step_type.settings.choices[:data].include?(node.config["data"])

      answer = ActiveRecord::Base.transaction(requires_new: true) do
        EasyFlow.data_source.carry_out(node.config["data"], Inputs.values_of(node, state))
      end.as_json
      (answer.is_a?(Hash) ? answer : { "answer" => answer }).merge("result" => "passed")
    rescue => error
      { "result" => "failed", "reason" => error.message }
    end
  end
end
