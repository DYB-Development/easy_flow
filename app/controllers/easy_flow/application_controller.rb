module EasyFlow
  class ApplicationController < EasyFlow.base_controller.constantize
    include Hosted

    layout -> { flow_host.layout }
    helper KeystoneUiHelper

    rescue_from NotPublished, NotPermitted, Withdrawn, with: :refuse

    helper_method :flow_start_path, :flow_routes

    private

    def flow_routes
      return easy_flow unless request.routes.equal?(EasyFlow::Engine.routes)

      @flow_routes ||= ActionDispatch::Routing::RoutesProxy.new(_routes, self, _routes.url_helpers)
    end

    def flow_start_path(slug)
      flow_routes.flow_path(slug)
    end

    def admit(flow)
      Admission.of(flow, permitted: permitted?(flow))
    end

    def permitted?(flow)
      return false unless flow_host.visitor_authorization_method

      send(flow_host.visitor_authorization_method, flow)
    end

    def refuse(refusal)
      return head :not_found unless flow_host.refusal_method

      send(flow_host.refusal_method, refusal)
    end
  end
end
