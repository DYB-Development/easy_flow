module EasyFlow
  module Manage
    class FlowsController < BaseController
      include DrawsCanvas
      def index
        @flows = ordered_flows
      end

      def create
        @flow = flow_host.flows.new(create_params)

        if @flow.save
          redirect_to manage_flow_path(@flow), notice: "Flow created."
        else
          @flows = ordered_flows
          render :index, status: :unprocessable_entity
        end
      end

      def show
        @flow = flow_host.flows.find(params[:id])
        @canvas = canvas_payload(@flow)
      end

      def edit
        @flow = flow_host.flows.find(params[:id])
      end

      def update
        @flow = flow_host.flows.find(params[:id])
        @flow.update!(flow_params)
        redirect_to manage_flow_path(@flow), notice: "Saved."
      end

      def destroy
        flow_host.flows.find(params[:id]).destroy!
        redirect_to manage_flows_path, notice: "Flow removed."
      end

      private

      def ordered_flows
        flow_host.flows.order(:slug)
      end

      def create_params
        params.require(:flow).permit(:slug, :kind)
      end

      def flow_params
        params.require(:flow).permit(:title, :start_label, :persists)
      end
    end
  end
end
