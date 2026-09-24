require "keystone_ui/react/mount_helper"

module EasyFlow
  module Manage
    class BaseController < EasyFlow.base_controller.constantize
      include Hosted

      before_action :refuse_a_host_not_set_up

      include AuthenticatesAdmin

      layout -> { EasyFlow.admin_layout }

      helper KeystoneUiHelper
      helper KeystoneUi::React::MountHelper

      private

      def refuse_a_host_not_set_up
        head :not_found unless flow_host.set_up?
      end
    end
  end
end
