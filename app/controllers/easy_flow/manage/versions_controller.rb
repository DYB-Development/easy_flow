module EasyFlow
  module Manage
    class VersionsController < BaseController
      def index
        @flow = flow
        @versions = @flow.definition_versions.order(number: :desc)
      end

      def return
        flow.return_to(flow.definition_versions.find(params[:id]))

        redirect_to manage_flow_path(flow), notice: "The flow is back to that version."
      end

      private

      def flow
        @flow ||= flow_host.flows.find(params[:flow_id])
      end
    end
  end
end
