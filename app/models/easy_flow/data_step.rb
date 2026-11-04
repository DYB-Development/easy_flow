module EasyFlow
  module DataStep
    extend ActiveSupport::Concern
    include Inputs

    def process(node, state)
      answer = EasyFlow.data_source.carry_out(node.config["data"], Inputs.values_of(node, state))
      answer.is_a?(Hash) ? answer : { "answer" => answer }
    end
  end
end
