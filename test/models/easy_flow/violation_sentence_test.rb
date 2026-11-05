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
  end
end
