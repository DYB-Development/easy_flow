require "test_helper"

module EasyFlow
  class TerminalTest < ActiveSupport::TestCase
    test "ends the flow that reaches it" do
      assert_predicate Terminal.step_type, :ends_here?
    end

    test "takes the output the flow writes when it ends there, typed in" do
      assert_equal :string, Terminal.step_type.settings.fields[:output]
    end

    test "is registered for a flow to use" do
      assert_equal :terminal, EasyFlow.registry.fetch("terminal").id
    end
  end
end
