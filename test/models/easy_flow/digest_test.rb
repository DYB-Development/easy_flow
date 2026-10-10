require "test_helper"

module EasyFlow
  class DigestTest < ActiveSupport::TestCase
    def registry
      @registry ||= Registry.new.tap do |built|
        built.register(StepType.define(:ask) { setting :text, type: :string; awaits_input })
        built.register(Terminal.step_type)
        built.register(StepType.define(:pick) { output :answer, values: ->(node) { Array(node.config["options"]) } })
        built.register(StepType.define(:check) do
          output :result, type: :boolean, values: [ true, false ]
          route { |_node, state| state["a"] == "yes" }
        end)
        built.register(StepType.define(:act) { process { |node, _state| "ran #{node.id}" } })
        built.register(StepType.define(:report) do
          setting(:values, type: :list) { setting :name, type: :string }
          outputs_named_by :values
        end)
        built.register(StepType.define(:branch) do
          setting :answer, type: :previous_step
          route { |node, state| state[node.config["answer"]] == "yes" ? :yes : :no }
        end)
      end
    end

    def acting
      { "entry" => "work",
        "nodes" => [ { "id" => "work", "type" => "act" },
                     { "id" => "after", "type" => "ask" } ],
        "edges" => [ { "from" => "work", "to" => "after" } ] }
    end

    def ending
      { "entry" => "q",
        "nodes" => [ { "id" => "q", "type" => "ask" },
                     { "id" => "done", "type" => "terminal", "output" => "bought" } ],
        "edges" => [ { "from" => "q", "to" => "done" } ] }
    end

    test "gives the output of the End step a finished walk ends on" do
      assert_equal "bought", digest(ending).output({ "q" => "yes" })
    end

    test "gives no output when the End step a finished walk ends on was left blank" do
      blank = ending.merge("nodes" => [ { "id" => "q", "type" => "ask" }, { "id" => "done", "type" => "terminal", "output" => "" } ])

      assert_nil digest(blank).output({ "q" => "yes" })
    end

    test "stops at a step whose process has not run" do
      assert_equal "work", digest(acting).next_step({}).id
    end

    def deciding
      { "entry" => "gate",
        "nodes" => [ { "id" => "gate", "type" => "check" },
                     { "id" => "yes_step", "type" => "ask" },
                     { "id" => "no_step", "type" => "ask" } ],
        "edges" => [ { "from" => "gate", "to" => "yes_step", "on" => true },
                     { "from" => "gate", "to" => "no_step", "on" => false } ] }
    end

    def digest(document)
      Digest.new(Document.new(flowing(document)), registry: registry)
    end

    def branching
      { "entry" => "first",
        "nodes" => [ { "id" => "first", "type" => "ask", "text" => "First?" },
                     { "id" => "gate", "type" => "branch", "answer" => "first" },
                     { "id" => "yes_step", "type" => "ask" },
                     { "id" => "no_step", "type" => "ask" },
                     { "id" => "last", "type" => "ask" } ],
        "edges" => [ { "from" => "first", "to" => "gate" },
                     { "from" => "gate", "to" => "yes_step", "on" => "yes" },
                     { "from" => "gate", "to" => "no_step", "on" => "no" },
                     { "from" => "yes_step", "to" => "last" },
                     { "from" => "no_step", "to" => "last" } ] }
    end

    test "reports the step a flow begins at" do
      assert_equal "start", digest(branching).entry.id
    end

    test "finds a step by its id" do
      assert_equal "gate", digest(branching).step("gate").id
    end

    test "reports what a step requires" do
      assert_equal [ "first" ], digest(branching).requirements("gate")
    end

    test "reports nothing required by a step that declares none" do
      assert_empty digest(branching).requirements("first")
    end

    test "the first step is the one a flow reaches with nothing recorded" do
      assert_equal "first", digest(branching).next_step({}).id
    end

    test "a step that awaits nothing is passed straight through" do
      assert_equal "yes_step", digest(branching).next_step({ "first" => "yes" }).id
    end

    test "a branching step sends the flow down the path its state selects" do
      assert_equal "no_step", digest(branching).next_step({ "first" => "no" }).id
    end

    test "the flow reaches the step both branches share" do
      assert_equal "last", digest(branching).next_step({ "first" => "no", "no_step" => "x" }).id
    end

    test "a finished flow reaches no further step" do
      assert_nil digest(branching).next_step({ "first" => "no", "no_step" => "x", "last" => "y" })
    end

    test "state on the path leaves out what an abandoned branch recorded" do
      wandered = { "first" => "no", "yes_step" => "stale", "no_step" => "x" }

      assert_equal({ "first" => "no", "no_step" => "x" }, digest(branching).state_on_path(wandered))
    end

    test "traversal ends on a flow whose edges form a cycle" do
      looping = { "entry" => "a",
                  "nodes" => [ { "id" => "a", "type" => "branch", "answer" => "nothing" }, { "id" => "b", "type" => "branch", "answer" => "nothing" } ],
                  "edges" => [ { "from" => "a", "to" => "b", "on" => "no" }, { "from" => "b", "to" => "a", "on" => "no" } ] }

      assert_nil digest(looping).next_step({})
    end

    test "reports the steps that come before a step on every path to it" do
      assert_equal [ "start", "first", "gate" ], digest(branching).preceding("last")
    end

    test "reports nothing before a step the entry cannot reach" do
      assert_empty digest(branching.merge("edges" => [])).preceding("last")
    end

    test "takes the edge marked false when a step routes to false" do
      assert_equal "no_step", digest(deciding).next_step({ "a" => "no" }).id
    end

    test "reports the values a step offers a later one" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "pick", "options" => [ { "value" => "high" } ] } ],
                   "edges" => [] }

      assert_equal [ { "value" => "high" } ], digest(document).values_out_of("a")
    end

    test "reports the values a step directs on" do
      assert_equal [ "true", "false" ], digest(deciding).routing_values("gate")
    end

    test "reports no directing values for a step that does not route" do
      assert_empty digest(branching).routing_values("first")
    end

    test "reports the names entered on a step whose list setting names its outputs" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a", "type" => "report", "values" => [ { "name" => "coverage" } ] } ], "edges" => [] }

      assert_equal [ { "value" => "coverage", "label" => "Coverage" } ], digest(document).outputs_of("a")
    end

    test "reports the outputs a step names for a later one to read" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a", "type" => "pick" } ], "edges" => [] }

      assert_equal [ { "value" => "answer", "label" => "Answer" } ], digest(document).outputs_of("a")
    end

    test "reports the values one named output of a step can take" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "pick", "options" => [ { "value" => "high" } ] } ],
                   "edges" => [] }

      assert_equal [ { "value" => "high" } ], digest(document).values_of("a", "answer")
    end

    def asking_again
      { "entry" => "name",
        "nodes" => [ { "id" => "name", "type" => "ask" },
                     { "id" => "more", "type" => "ask" },
                     { "id" => "again", "type" => "branch", "answer" => "more" },
                     { "id" => "done", "type" => "ask" } ],
        "edges" => [ { "from" => "name", "to" => "more" },
                     { "from" => "more", "to" => "again" },
                     { "from" => "again", "to" => "name", "on" => "yes" },
                     { "from" => "again", "to" => "done", "on" => "no" } ] }
    end

    test "a flow that branches back to a question already answered asks it again under its next visit" do
      assert_equal "name@2", digest(asking_again).next_step({ "name" => "Mowing", "more" => "yes" }).id
    end

    test "a branch in a loop reads the latest answer to the question it checks" do
      assert_equal "done", digest(asking_again).next_step({ "name" => "Mowing", "more" => "yes", "name@2" => "Edging", "more@2" => "no" }).id
    end

    test "the answers on a looping flow's path keep every visit" do
      answers = { "name" => "Mowing", "more" => "yes", "name@2" => "Edging", "more@2" => "no", "done" => "ok" }

      assert_equal answers, digest(asking_again).state_on_path(answers)
    end

    test "finds a question by the key of a later visit to it" do
      assert_equal "name", digest(asking_again).step("name@2").id
    end
  end
end
