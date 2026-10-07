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

        flow = Definition.find(node.config["flow"])
        Run.start(flow, version: flow.definition_versions.find_by(number: node.config["version"]))
          .tap { |inner| inner.update!(parent_run: @run, parent_step: node.id) }.advance
      end

      def ended
        parent = @run.parent_run or return
        return if parent.recorded.key?(@run.parent_step.to_sym)

        parent.record(@run.parent_step.to_sym, @run.output)
        AdvanceParentJob.perform_later(parent)
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
