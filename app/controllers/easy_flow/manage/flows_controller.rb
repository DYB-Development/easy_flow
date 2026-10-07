module EasyFlow
  module Manage
    class FlowsController < BaseController
      include DrawsCanvas
      def index
        @flows = ordered_flows
      end

      def new
        @flow = hosted_flows.new
      end

      def create
        @flow = hosted_flows.new(create_params)

        if @flow.save
          redirect_to manage_flow_path(@flow), notice: "Flow created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def show
        @flow = hosted_flows.find(params[:id])
        @parent = hosted_flows.find_by(id: params[:from])
        @canvas = canvas_payload(@flow)
      end

      def edit
        @flow = hosted_flows.find(params[:id])
      end

      def update
        @flow = hosted_flows.find(params[:id])
        @flow.update!(flow_params)
        redirect_to manage_flow_path(@flow), notice: "Saved."
      end

      def destroy
        flow = hosted_flows.find(params[:id])
        return redirect_to manage_flows_path, alert: flow.errors.full_messages.to_sentence unless flow.destroy

        redirect_to manage_flows_path, notice: "Flow removed."
      end

      private

      def ordered_flows
        hosted_flows.order(:slug)
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
