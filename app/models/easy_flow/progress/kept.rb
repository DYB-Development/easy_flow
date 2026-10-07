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

        chosen = ChosenFlow.of(node)
        Run.start(chosen.flow || raise(ActiveRecord::RecordNotFound), version: chosen.version)
          .tap { |inner| inner.update!(parent_run: @run, parent_step: node.id, owner: @run.owner) }.advance
      end

      def ended
        parent = @run.parent_run or return
        return if parent.recorded.key?(@run.parent_step.to_sym)

        parent.record(@run.parent_step.to_sym, @run.output) if @run.output
        AdvanceParentJob.perform_later(parent, @run.parent_step)
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
