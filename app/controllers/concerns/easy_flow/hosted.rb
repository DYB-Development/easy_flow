module EasyFlow
  module Hosted
    extend ActiveSupport::Concern

    included do
      class_attribute :named_flow_host, instance_accessor: false
    end

    class_methods do
      def hosted_by(name)
        self.named_flow_host = name.to_s
      end
    end

    private

    def flow_host
      @flow_host ||= EasyFlow.host_named(self.class.named_flow_host || request.path_parameters[:easy_flow_host])
    end
  end
end
