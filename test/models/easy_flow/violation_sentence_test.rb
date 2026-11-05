require "test_helper"

module EasyFlow
  class ViolationSentenceTest < ActiveSupport::TestCase
    def registry
      Registry.new.tap do |built|
        built.register(StepType.define(:told) do
          step_name "Told"
          setting :text, type: :string
          setting :other_output, type: :string
          setting(:comparisons, type: :list) { setting :other_output, type: :string }
          names_by :text
        end)
      end
    end

    def document
      Document.new({ "entry" => "check", "edges" => [],
        "nodes" => [ { "id" => "check", "type" => "told", "text" => "Check the new test fails" },
                     { "id" => "fix", "type" => "told", "text" => "Fix the tests" },
                     { "id" => "nameless_step", "type" => "told" },
                     { "id" => "snake", "type" => "told", "text" => "run_tests" } ] }, registry: registry)
    end

    def sentence(problem, node: "check", detail: nil)
      ViolationSentence.new(document, registry: registry).of(Violation.new(node: node, problem: problem, detail: detail))
    end

    test "says a step that goes nowhere leads nowhere and what to do" do
      assert_equal "Check the new test fails leads nowhere. Connect it to the step that should come next.", sentence(:dead_end)
    end

    test "writes an underscore in a step's name as a space" do
      assert_equal "run tests leads nowhere. Connect it to the step that should come next.", sentence(:dead_end, node: "snake")
    end

    test "says which way out of a step leads nowhere" do
      assert_equal "Passed on Check the new test fails leads nowhere. Connect it to the step that should come next.", sentence(:unrouted_value, detail: "passed")
    end

    test "says a step is not connected to the flow" do
      assert_equal "Check the new test fails is not connected to the flow. Connect a step to it, or delete it.", sentence(:unreachable)
    end

    test "says an end step has a connection leaving it" do
      assert_equal "Check the new test fails ends the flow, but a connection leaves it. Remove that connection.", sentence(:past_the_end)
    end

    test "names both steps of a connection that is never followed" do
      assert_equal "The connection from Check the new test fails to Fix the tests is never followed, because Check the new test fails only follows its first connection. Remove the connection to Fix the tests.", sentence(:unfollowed_path, detail: "fix")
    end
  end
end
