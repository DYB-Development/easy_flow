module EasyFlow
  module Manage
    module AuthenticatesAdmin
      extend ActiveSupport::Concern

      included do
        before_action :authenticate_admin
      end

      private

      def authenticate_admin
        return unless flow_host.admin_authentication_method

        send(flow_host.admin_authentication_method)
      end
    end
  end
end
