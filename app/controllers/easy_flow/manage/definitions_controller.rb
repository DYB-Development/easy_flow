module EasyFlow
  module Manage
    class DefinitionsController < BaseController
      def edit
        @flow = flow_host.flows.find(params[:flow_id])
      end

      def update
        @flow = flow_host.flows.find(params[:flow_id])
        @flow.edit_history.edit_document(JSON.parse(params.require(:definition)))
        redirect_to manage_flow_path(@flow), notice: "Definition saved."
      end
    end
  end
end
