require "test_helper"

module EasyFlow
  class CoreIsolationTest < ActiveSupport::TestCase
    def foreign
      @foreign ||= Registry.new.tap do |built|
        built.register(StepType.define(:opening) { begins_here; names_by { |_node| "Opening" } })
        built.register(StepType.define(:draft) do
          setting :prompt, type: :string
          awaits_input
          names_by :prompt
        end)
        built.register(StepType.define(:gate) do
          setting :of, type: :previous_step
          output :verdict, label: "Verdict", values: [ { "value" => "approved" }, { "value" => "rejected" } ]
          route { |node, state| state[node.config["of"]] == "ok" ? "approved" : "rejected" }
        end)
      end
    end

    def orchestration
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "draft", "type" => "draft", "prompt" => "Draft it" },
                     { "id" => "gate", "type" => "gate", "of" => "draft" },
                     { "id" => "polish", "type" => "draft", "prompt" => "Polish it" },
                     { "id" => "explain", "type" => "draft", "prompt" => "Explain why" } ],
        "edges" => [ { "from" => "opening", "to" => "draft" },
                     { "from" => "draft", "to" => "gate" },
                     { "from" => "gate", "to" => "polish", "on" => "approved" },
                     { "from" => "gate", "to" => "explain", "on" => "rejected" } ] }
    end

    def document
      Document.new(orchestration, registry: foreign)
    end

    def digest
      Digest.new(document, registry: foreign)
    end

    test "begins at the step whose own type says it begins there" do
      assert_equal "opening", document.entry
    end

    test "stops at the first step of its own that awaits input" do
      assert_equal "draft", digest.next_step({}).id
    end

    test "routes on the port a step type of its own returns" do
      assert_equal "polish", digest.next_step({ "draft" => "ok" }).id
    end

    test "routes to the other branch on the other port" do
      assert_equal "explain", digest.next_step({ "draft" => "no" }).id
    end

    test "drops state stranded off the branch taken" do
      wandered = { "draft" => "ok", "explain" => "stale", "polish" => "done" }

      assert_equal({ "draft" => "ok", "polish" => "done" }, digest.state_on_path(wandered))
    end

    test "names a step by the naming its own type declares" do
      assert_equal "Draft it", Name.of(document.node("draft"), foreign)
    end

    test "finds no fault in a document built only of step types of its own" do
      assert_empty Validator.new(document, registry: foreign, checks: []).violations
    end
  end
end
