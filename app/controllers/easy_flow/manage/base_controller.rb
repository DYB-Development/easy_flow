require "keystone_ui/react/mount_helper"

module EasyFlow
  module Manage
    class BaseController < EasyFlow.base_controller.constantize
      include Hosted
      include AuthenticatesAdmin

      layout -> { EasyFlow.admin_layout }

      helper KeystoneUiHelper
      helper KeystoneUi::React::MountHelper
    end
  end
end
