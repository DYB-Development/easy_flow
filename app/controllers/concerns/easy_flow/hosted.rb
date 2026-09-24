module EasyFlow
  module Hosted
    extend ActiveSupport::Concern

    private

    def flow_host
      @flow_host ||= EasyFlow.host_named(request.path_parameters[:easy_flow_host])
    end
  end
end
