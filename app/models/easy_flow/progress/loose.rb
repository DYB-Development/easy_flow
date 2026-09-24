module EasyFlow
  module Progress
    class Loose
      def initialize(flow, answers, definition = nil)
        @flow = flow
        @answers = answers.to_h.symbolize_keys
        @definition = definition
      end

      def definition
        @definition || @flow.live_definition
      end

      def recorded
        @answers
      end

      def record(id, value)
        @answers = @answers.merge(id.to_sym => value)
      end

      def finish(state)
        return unless @flow.on_finish?

        Run.start(@flow).tap { |run| run.update!(recorded: state) }
      end

      def discard_last
        last = Runner.new(@flow.live_definition).state_on_path(@answers).keys.last

        @answers = @answers.except(last) if last
      end
    end
  end
end
