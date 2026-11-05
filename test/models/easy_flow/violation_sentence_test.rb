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

    test "names a missing setting by its label" do
      assert_equal "Check the new test fails needs a value for Other output. Set it in the step's settings.", sentence(:missing_setting, detail: "other_output")
    end

    test "names a missing setting inside a list by the list and the entry's position" do
      assert_equal "Check the new test fails needs a value for Other output in Comparisons entry 2. Set it in the step's settings.", sentence(:missing_setting, detail: "comparisons 2 other_output")
    end

    test "says a picked answer is no longer offered" do
      assert_equal "Check the new test fails picks the answer maybe later, which the earlier step no longer offers. Pick another answer in the step's settings.", sentence(:missing_value, detail: "maybe_later")
    end

    test "says a step reads one that not every path goes through" do
      assert_equal "Check the new test fails reads Fix the tests, which not every path to it goes through. Move Fix the tests ahead of it on every path, or pick another step in its settings.", sentence(:unmet_requirement, detail: "fix")
    end

    test "says a step reads one that no longer exists" do
      assert_equal "Check the new test fails reads a step that no longer exists. Pick another step in its settings.", sentence(:unmet_requirement, detail: "gone")
    end

    test "says a connection leads to a step that does not exist" do
      assert_equal "A connection from Check the new test fails leads to a step that does not exist. Remove it in the flow's definition.", sentence(:missing_edge_target, detail: "gone")
    end

    test "says a connection comes from a step that does not exist" do
      assert_equal "A connection into Check the new test fails comes from a step that does not exist. Remove it in the flow's definition.", sentence(:missing_edge_source, detail: "gone")
    end

    test "says two steps share an id without showing it" do
      assert_equal "Check the new test fails has the same id as another step. Change one of the ids in the flow's definition.", sentence(:duplicate_id)
    end

    test "says a step's id holds an at sign" do
      assert_equal "Check the new test fails has an id with an @ in it, which a flow cannot use. Change the id in the flow's definition.", sentence(:reserved_id)
    end

    test "says a flow has no start step" do
      assert_equal "This flow has no start step. Add one in the flow's definition.", sentence(:no_beginning, node: nil)
    end
  end
end
