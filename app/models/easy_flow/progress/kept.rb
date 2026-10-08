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

      def record(id, value)
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
        return if parent.recorded.key?(@run.parent_step.to_sym)

        ending = @run.output || ("ended" if chose_from_run?(parent))
        parent.record(@run.parent_step.to_sym, ending) if ending
        AdvanceParentJob.perform_later(parent, @run.parent_step)
      end

      def chose_from_run?(parent)
        type = parent.pinned_steps.dig(@run.parent_step, "type")
        EasyFlow.registry.registered?(type) && EasyFlow.registry.fetch(type).chooses_flow_from_run?
      end

      def finish(_state)
        @run
      end

      def discard_last
        @run.discard_last
      end
    end
  end
end
