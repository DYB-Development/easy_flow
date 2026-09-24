module EasyFlow
  module Manage
    module DrawsCanvas
      extend ActiveSupport::Concern

      private

      def canvas_payload(flow)
        Canvas.new(canvas_document(flow)).to_h
          .merge("undoable" => flow.edit_history.undoable?, "redoable" => flow.edit_history.redoable?,
                 "changes" => listed_changes(flow), "flow" => flow_details(flow))
      end

      def canvas_document(flow)
        Document.new(flow.document || flow.definition || {})
      end

      def listed_changes(flow)
        flow.changes_since_version.to_a.map { |change| Change.phrase(change) }
      end

      def flow_details(flow)
        { "title" => flow.title,
          "slug" => flow.slug,
          "start_label" => flow.start_label,
          "version" => flow.current_definition_version&.number,
          "published" => flow.live_version&.number,
          "definition_url" => edit_manage_flow_definition_path(flow),
          "details_url" => edit_manage_flow_path(flow),
          "history_url" => manage_flow_versions_path(flow) }
      end
    end
  end
end
