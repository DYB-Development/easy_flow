module EasyFlow
  class ApplicationController < EasyFlow.base_controller.constantize
    layout -> { EasyFlow.layout }
    helper KeystoneUiHelper

    rescue_from NotPublished, NotPermitted, Withdrawn, with: :refuse

    helper_method :flow_start_path

    private

    def flow_start_path(slug)
      easy_flow.flow_path(slug)
    end

    def admit(flow)
      Admission.of(flow, permitted: permitted?(flow))
    end

    def permitted?(flow)
      return false unless EasyFlow.visitor_authorization_method

      send(EasyFlow.visitor_authorization_method, flow)
    end

    def refuse(refusal)
      return head :not_found unless EasyFlow.refusal_method

      send(EasyFlow.refusal_method, refusal)
    end
  end
end
