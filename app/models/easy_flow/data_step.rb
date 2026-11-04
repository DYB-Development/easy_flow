module EasyFlow
  module DataStep
    extend ActiveSupport::Concern
    include Inputs

    def process(node, state)
      EasyFlow.data_source.carry_out(node.config["data"], Inputs.values_of(node, state))
    end
  end
end
