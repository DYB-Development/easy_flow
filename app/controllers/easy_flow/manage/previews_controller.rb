module EasyFlow
  module Manage
    class PreviewsController < ::EasyFlow::FlowsController
      include AuthenticatesAdmin

      def show
        @flow = previewed
        render template: "easy_flow/flows/show"
      end

      private

      def flow_start_path(_slug)
        manage_flow_preview_path(previewed)
      end

      def flow_step_path(_slug)
        step_manage_flow_preview_path(previewed)
      end

      def previewing?
        true
      end

      def flowing_definition(flow)
        flow.document
      end

      def previewed
        @previewed ||= flow_host.flows.find(params[:flow_id])
      end

      def admit(_flow)
        previewed
      end
    end
  end
end
