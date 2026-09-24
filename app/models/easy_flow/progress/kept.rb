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

      def finish(_state)
        @run
      end

      def discard_last
        @run.discard_last
      end
    end
  end
end
