module EasyFlow
  module Progress
    class Loose
      def initialize(flow, answers, definition = nil, answered_at = {})
        @flow = flow
        @answers = answers.to_h.symbolize_keys
        @definition = definition
        @answered_at = answered_at.to_h.symbolize_keys
      end

      attr_reader :answered_at

      def definition
        @definition || @flow.live_definition
      end

      def recorded
        @answers
      end

      def record(id, value)
        @answers = @answers.merge(id.to_sym => value)
        @answered_at = @answered_at.merge(id.to_sym => Time.current)
      end

      def start_inner(_node); end

      def ended; end

      def finish(state)
        return unless @flow.on_finish?

        Run.start(@flow).tap { |run| run.update!(recorded: state, answered_at: @answered_at.slice(*state.keys.map(&:to_sym))) }
      end

      def discard_last
        last = Runner.new(@flow.live_definition).state_on_path(@answers, times: @answered_at).keys.last
        return unless last

        @answers = @answers.except(last)
        @answered_at = @answered_at.except(last)
      end
    end
  end
end
