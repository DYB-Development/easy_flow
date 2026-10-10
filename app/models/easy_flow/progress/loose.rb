module EasyFlow
  module Progress
    class Loose
      def initialize(flow, answers, definition = nil, completed_at = {})
        @flow = flow
        @answers = answers.to_h.symbolize_keys
        @definition = definition
        @completed_at = completed_at.to_h.symbolize_keys
      end

      attr_reader :completed_at

      def definition
        @definition || @flow.live_definition
      end

      def recorded
        @answers
      end

      def record(id, value)
        @answers = @answers.merge(id.to_sym => value)
        @completed_at = @completed_at.merge(id.to_sym => Time.current)
      end

      def start_inner(_node); end

      def ended; end

      def finish(state)
        return unless @flow.on_finish?

        Run.start(@flow).tap do |run|
          run.update!(recorded: state.to_h { |step_id, value| [ step_id.to_s, { "value" => value, "completed_at" => @completed_at[step_id.to_sym]&.utc&.iso8601 }.compact ] })
        end
      end

      def discard_last
        last = Runner.new(@flow.live_definition).state_on_path(@answers, times: @completed_at).keys.last
        return unless last

        @answers = @answers.except(last)
        @completed_at = @completed_at.except(last)
      end
    end
  end
end
