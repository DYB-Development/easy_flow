module EasyFlow
  module Progress
    class Kept
      def initialize(run)
        @run = run
      end

      def definition
        @run.pinned_definition
      end

      def recorded
        @run.recorded
      end

      def completed_at
        @run.completed_at
      end

      def record(id, value)
        return play(id, value) if plays_the_picked_flow?(id)

        @run.record(id.to_sym, value)
      end

      def start_inner(node)
        return if @run.inner_runs.exists?(parent_step: node.id)

        chosen = ChosenFlow.of(node, run: @run)
        raise InnerFlowError, "The step #{node.id} chose no flow to run" if chosen.flow.nil? && EasyFlow.registry.fetch(node.type).chooses_flow_from_run?
        raise InnerFlowError, "The Flow step #{node.id} names a version that cannot run" if chosen.version&.out_of_service?
        Run.start(chosen.flow || raise(ActiveRecord::RecordNotFound), version: chosen.version)
          .tap { |inner| inner.update!(parent_run: @run, parent_step: node.id, owner: @run.owner) }.advance
      end

      def ended
        parent = @run.parent_run or return
        return if @run.stopped_on_loop
        return if parent.recorded.key?(@run.parent_step.to_sym)

        parent.record(@run.parent_step.to_sym, @run.output || "ended")
        AdvanceParentJob.perform_later(parent, @run.parent_step)
      end

      def finish(_state)
        @run
      end

      def discard_last
        @run.discard_last
      end

      private

      def plays_the_picked_flow?(id)
        node = @run.digest.step(id)
        node && EasyFlow.registry.registered?(node.type) && EasyFlow.registry.fetch(node.type).plays_the_picked_flow?
      end

      def play(id, flow_id)
        return if @run.inner_runs.exists?(parent_step: id.to_s)
        return unless offered?(id, flow_id)

        Run.start(Definition.find(flow_id)).tap { |inner| inner.update!(parent_run: @run, parent_step: id.to_s, owner: @run.owner) }.advance
      end

      def offered?(id, flow_id)
        node = @run.digest.step(id)
        EasyFlow.registry.fetch(node.type).display_of(node.with(id: id.to_s), @run).choices.map(&:value).include?(flow_id.to_s)
      end
    end
  end
end
