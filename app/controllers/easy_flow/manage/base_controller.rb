require "keystone_ui/react/mount_helper"

module EasyFlow
  module Manage
    class BaseController < EasyFlow.base_controller.constantize
      include Hosted

      before_action :refuse_a_host_not_set_up

      include AuthenticatesAdmin

      layout -> { flow_host.admin_layout }

      helper KeystoneUiHelper
      helper KeystoneUi::React::MountHelper
      helper EasyFlow::Engine.routes.url_helpers

      helper_method :flow_routes

      private

      def flow_routes
        @flow_routes ||= ActionDispatch::Routing::RoutesProxy.new(_routes, self, _routes.url_helpers)
      end

      def refuse_a_host_not_set_up
        head :not_found unless flow_host.set_up?
      end
    end
  end
end
