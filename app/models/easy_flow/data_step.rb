module EasyFlow
  module DataStep
    extend ActiveSupport::Concern
    include Inputs

    def process(node, state)
      answer = EasyFlow.data_source.carry_out(node.config["data"], Inputs.values_of(node, state)).as_json
      (answer.is_a?(Hash) ? answer : { "answer" => answer }).merge("result" => "passed")
    end
  end
end
