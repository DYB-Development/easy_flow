module EasyFlow
  module Manage
    class CanvasController < BaseController
      include DrawsCanvas
      def show
        render json: canvas_payload(flow)
      end

      def create
        objections = Validator.new(document).violations
        return render json: { error: refusal(objections) }, status: :unprocessable_entity if objections.any?

        stood_at = flow.current_definition_version&.number
        flow.create_version

        render json: { notice: created(stood_at) }
      end

      def publish
        objections = Validator.new(document).violations
        return render json: { error: refusal(objections) }, status: :unprocessable_entity if objections.any?

        ran = flow.live_version&.number
        flow.publish

        render json: { notice: published(ran) }
      end

      def details
        flow.update!(details_params)
        render json: { notice: "Saved the flow's details." }
      end

      def undo
        flow.edit_history.undo_change
        head :no_content
      end

      def redo
        flow.edit_history.redo_change
        head :no_content
      end

      def add_step
        apply(:added, params[:id]) do |edited|
          next edited.insert(new_step, on: edge_endpoints, leaving: first_port) if placed_on_edge?
          next edited.add(new_step).connect(from: params[:from], to: params[:id], on: params[:on].presence) if branched_from?

          edited.add(new_step)
        end
      end

      def configure_step
        apply(:updated, params[:step]) { |edited| edited.configure(params[:step], coerced(edited, params[:step])) }
      end

      def move_step
        apply(:moved, params[:step]) { |edited| edited.move(params[:step], on: edge_endpoints, leaving: port_for(params[:step])) }
      end

      def remove_step
        return render json: { error: refusal_to_remove }, status: :unprocessable_entity if begins_the_flow?(params[:step])

        apply(:removed, params[:step]) { |edited| edited.remove(params[:step]) }
      end

      def connect
        apply(:connected, params[:from], params[:to]) { |edited| edited.connect(from: params[:from], to: params[:to], on: params[:on].presence) }
      end

      def disconnect
        apply(:disconnected, params[:from], params[:to]) { |edited| edited.disconnect(from: params[:from], to: params[:to]) }
      end

      private

      def apply(action = nil, *steps)
        before = document.to_h
        flow.edit_history.record(yield(document), action, steps, before)
        head :no_content
      rescue InvalidEdit => invalid
        render json: { error: invalid.message }, status: :unprocessable_entity
      end

      def flow
        @flow ||= flow_host.flows.find(params[:flow_id])
      end

      def document
        Document.new(flow.document || flow.definition || {})
      end

      def details_params
        params.require(:flow).permit(:title, :start_label, :persists)
      end

      def new_step
        { "id" => params.require(:id), "type" => params.require(:type) }
      end

      def first_port
        first_value_of(Node.new(id: nil, type: params[:type], config: {}))
      end

      def port_for(id)
        first_value_of(document.node(id))
      end

      def first_value_of(node)
        return unless node && EasyFlow.registry.registered?(node.type)

        step_type = EasyFlow.registry.fetch(node.type)
        return unless step_type.routes?

        step_type.outputs.flat_map { |output| output.values_for(node) }.first&.fetch("value", nil)&.to_s
      end

      def begins_the_flow?(id)
        node = document.node(id)

        node.present? && document.begins_here?(node)
      end

      def placed_on_edge?
        params[:from].present? && params[:to].present?
      end

      def branched_from?
        params[:from].present?
      end

      def edge_endpoints
        [ params[:from], params[:to] ]
      end

      def configuration
        params.fetch(:config, {}).permit!.to_h
      end

      def created(stood_at)
        now_at = flow.reload.current_definition_version&.number
        return "Nothing has changed since version #{stood_at}." if now_at == stood_at

        "Created version #{now_at}."
      end

      def published(ran)
        now_at = flow.reload.live_version&.number
        return "Visitors already run version #{now_at}." if now_at == ran

        "Published version #{now_at}. Visitors run it now."
      end

      def refusal_to_remove
        "Cannot remove where a flow begins."
      end

      def refusal(objections)
        "Cannot publish: #{objections.map { |problem| worded(problem) }.join(', ')}."
      end

      def worded(problem)
        trouble = problem.problem.to_s.humanize(capitalize: false)

        problem.node ? "“#{problem.node}” is #{trouble}" : trouble
      end

      def coerced(edited, id)
        step_type = Digest.new(edited).step(id)&.type
        return configuration unless step_type && EasyFlow.registry.registered?(step_type)

        settled(EasyFlow.registry.fetch(step_type))
      end

      def settled(step_type)
        step_type.settings.coerce(configuration).tap do |values|
          objections = step_type.settings.objections(values)
          raise InvalidEdit, objections.join(", ") if objections.any?
        end
      end
    end
  end
end
