require "test_helper"

module EasyFlow
  class ValidatorTest < ActiveSupport::TestCase
    def violations(document, registry = EasyFlow.registry, checks: [])
      Validator.new(Document.new(flowing(document)), registry: registry, checks: checks).violations
    end

    def needy_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:needy) { setting :needs, type: :previous_step })
        registry.register(StepType.define(:plain) { })
        registry.register(StepType.define(:forks) do
          output :way, values: [ "r", "x" ]
          route { |_node, _state| "r" }
        end)
      end
    end

    def needy_document(edges, leading: "plain")
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => leading }, { "id" => "r", "type" => "plain" },
                     { "id" => "x", "type" => "needy", "needs" => "r" } ],
        "edges" => edges }
    end

    test "accepts a requirement that lies on the only path to the step" do
      document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "r", "to" => "x" } ])

      assert_empty violations(document, needy_registry)
    end

    test "reports a requirement that lies on only one of two paths to the step" do
      document = needy_document([ { "from" => "a", "to" => "r", "on" => "r" }, { "from" => "r", "to" => "x" },
                                  { "from" => "a", "to" => "x", "on" => "x" } ], leading: "forks")

      assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
    end

    test "identifies the step and the requirement that is unmet" do
      document = needy_document([ { "from" => "a", "to" => "r", "on" => "r" },
                                  { "from" => "a", "to" => "x", "on" => "x" } ], leading: "forks")
      violation = violations(document, needy_registry).first

      assert_equal [ "x", "r" ], [ violation.node, violation.detail ]
    end

    test "reports a requirement naming a step the document does not carry" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "x", "type" => "needy", "needs" => "ghost" } ],
                   "edges" => [ { "from" => "a", "to" => "x" } ] }

      assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
    end

    test "never reports a step that requires nothing" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "x", "type" => "plain" } ],
                   "edges" => [ { "from" => "a", "to" => "x" } ] }

      assert_empty violations(document, needy_registry)
    end

    test "checks requirements on a document whose edges form a cycle" do
      document = needy_document([ { "from" => "a", "to" => "r" }, { "from" => "r", "to" => "x" }, { "from" => "x", "to" => "r" } ])

      assert_empty violations(document, needy_registry)
    end

    test "reports a requirement that lies on no path to the step" do
      document = needy_document([ { "from" => "a", "to" => "r", "on" => "r" },
                                  { "from" => "a", "to" => "x", "on" => "x" } ], leading: "forks")

      assert_equal [ :unmet_requirement ], violations(document, needy_registry).map(&:problem)
    end

    test "reports nothing for a whole document with none of these problems" do
      document = {
        "entry" => "ask", "nodes" => [ { "id" => "ask" }, { "id" => "branch" }, { "id" => "yes_step" }, { "id" => "no_step" } ],
        "edges" => [ { "from" => "ask", "to" => "branch" },
                     { "from" => "branch", "to" => "yes_step", "on" => "yes" },
                     { "from" => "branch", "to" => "no_step", "on" => "no" } ]
      }

      assert_empty violations(document)
    end

    test "reports a node that cannot be reached from the entry" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "stranded" } ], "edges" => [] }

      assert_equal [ :unreachable ], violations(document).map(&:problem)
    end

    test "reaches a node by following an edge from the entry" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ], "edges" => [ { "from" => "a", "to" => "b" } ] }

      assert_empty violations(document)
    end

    test "terminates on a document whose edges form a cycle" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                   "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "a" } ] }

      assert_empty violations(document)
    end

    test "reports a flow with nowhere it begins" do
      document = { "nodes" => [ { "id" => "a", "type" => "question" } ], "edges" => [] }

      assert_includes Validator.new(Document.new(document)).violations.map(&:problem), :no_beginning
    end

    test "reports two nodes sharing an id" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" }, { "id" => "a" } ] }

      assert_equal [ :duplicate_id ], violations(document).map(&:problem)
    end

    test "reports an edge leaving a node that does not exist" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "ghost", "to" => "a" } ] }

      assert_equal [ :missing_edge_source ], violations(document).map(&:problem)
    end

    test "anchors a missing edge target on the node the edge leaves" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

      assert_equal "a", violations(document).first.node
    end

    test "names the missing target as the violation's detail" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

      assert_equal "ghost", violations(document).first.detail
    end

    test "reports an edge pointing at a node that does not exist" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a" } ], "edges" => [ { "from" => "a", "to" => "ghost" } ] }

      assert_equal [ :missing_edge_target ], violations(document).map(&:problem)
    end

    def demanding_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:needs) { setting :step, type: :string, required: true })
      end
    end

    test "reports a step left without a setting it cannot run without" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a", "type" => "needs" } ], "edges" => [] }

      assert_equal [ :missing_setting ], violations(document, demanding_registry).map(&:problem)
    end

    def reading_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:pick) { output :answer, values: ->(node) { Array(node.config["options"]) } })
        registry.register(StepType.define(:reads) do
          setting :step, type: :previous_step
          setting :output, outputs_of: :step
          setting :answer, from: :output
        end)
      end
    end

    def reading_document(chosen)
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "pick", "options" => [ { "value" => "high" } ] },
                     { "id" => "b", "type" => "reads", "step" => "a", "output" => "answer", "answer" => chosen } ],
        "edges" => [ { "from" => "a", "to" => "b" } ] }
    end

    test "reports a step reading a value the step it names no longer offers" do
      assert_equal [ :missing_value ], violations(reading_document("gone"), reading_registry).map(&:problem)
    end

    test "accepts a step reading a value the step it names still offers" do
      assert_empty violations(reading_document("high"), reading_registry)
    end

    def deciding_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:plain) { })
        registry.register(StepType.define(:decides) do
          output :result, type: :boolean, values: [ true, false ]
          route { |_node, _state| true }
        end)
      end
    end

    def deciding_document(edges)
      { "entry" => "gate",
        "nodes" => [ { "id" => "gate", "type" => "decides" }, { "id" => "yes_step", "type" => "plain" },
                     { "id" => "no_step", "type" => "plain" } ],
        "edges" => edges }
    end

    test "reports a deciding step left without an edge for one of its results" do
      document = deciding_document([ { "from" => "gate", "to" => "yes_step", "on" => true } ])
      found = Validator.new(Document.new(flowing(document)), registry: deciding_registry, checks: [ :unrouted_value ]).violations

      assert_includes found.map(&:problem), :unrouted_value
    end

    test "accepts a deciding step wired for every result it can reach" do
      document = deciding_document([ { "from" => "gate", "to" => "yes_step", "on" => true },
                                     { "from" => "gate", "to" => "no_step", "on" => false } ])

      assert_empty violations(document, deciding_registry)
    end

    def listing_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:lists) { setting(:items, type: :list, required: true) { setting :value, type: :string } })
      end
    end

    test "reports a step whose list of things it needs holds no entries" do
      document = { "entry" => "a", "nodes" => [ { "id" => "a", "type" => "lists", "items" => [] } ], "edges" => [] }

      assert_equal [ :missing_setting ], violations(document, listing_registry).map(&:problem)
    end

    test "accepts a step whose list of things it needs holds an entry" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "lists", "items" => [ { "value" => "one" } ] } ],
                   "edges" => [] }

      assert_empty violations(document, listing_registry)
    end

    def leading_document(edges)
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "b", "type" => "plain" },
                     { "id" => "c", "type" => "plain" } ],
        "edges" => edges }
    end

    test "reports a step that cannot follow the second connection leaving it" do
      document = leading_document([ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" } ])
      found = Validator.new(Document.new(flowing(document)), registry: deciding_registry, checks: [ :unfollowed_path ]).violations

      assert_includes found.map(&:problem), :unfollowed_path
    end

    test "accepts a step with one connection leaving it" do
      document = leading_document([ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ])

      assert_empty violations(document, deciding_registry)
    end

    test "never reports a branching step, however many connections leave it" do
      document = { "entry" => "gate",
                   "nodes" => [ { "id" => "gate", "type" => "decides" }, { "id" => "b", "type" => "plain" },
                                { "id" => "c", "type" => "plain" } ],
                   "edges" => [ { "from" => "gate", "to" => "b", "on" => true },
                                { "from" => "gate", "to" => "c", "on" => false } ] }

      assert_empty violations(document, deciding_registry)
    end

    test "leaves a branching step's unwired result alone unless that check is asked for" do
      document = deciding_document([ { "from" => "gate", "to" => "yes_step", "on" => true } ])
      found = Validator.new(Document.new(flowing(document)), registry: deciding_registry, checks: []).violations

      assert_empty found.map(&:problem).select { |problem| problem == :unrouted_value }
    end

    test "reports an unwired result on a condition a flow actually uses" do
      document = { "entry" => "ask",
                   "nodes" => [ { "id" => "ask", "type" => "question", "question" => "Budget?",
                                  "answers" => [ { "value" => "high" } ] },
                                { "id" => "gate", "type" => "condition", "step" => "ask", "output" => "answer",
                                  "comparison" => "is", "answer" => "high" },
                                { "id" => "posh", "type" => "question", "question" => "Posh?",
                                  "answers" => [ { "value" => "yes" } ] } ],
                   "edges" => [ { "from" => "ask", "to" => "gate" },
                                { "from" => "gate", "to" => "posh", "on" => true } ] }

      assert_includes violations(document, EasyFlow.registry, checks: EasyFlow.checks).map(&:problem), :unrouted_value
    end

    def ending_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:plain) { })
        registry.register(StepType.define(:stop) { ends_here })
      end
    end

    def ending_document(last)
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "b", "type" => last } ],
        "edges" => [ { "from" => "a", "to" => "b" } ] }
    end

    def endings(document)
      Validator.new(Document.new(flowing(document)), registry: ending_registry, checks: [ :dead_end ]).violations
    end

    test "reports a step with nothing leading away from it that does not end the flow" do
      assert_equal [ :dead_end ], endings(ending_document("plain")).map(&:problem)
    end

    test "accepts a flow whose last step ends it" do
      assert_empty endings(ending_document("stop"))
    end

    test "reports a step leading on from where the flow ends" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "b", "type" => "stop" },
                                { "id" => "c", "type" => "stop" } ],
                   "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ] }

      assert_equal [ :past_the_end ], endings(document).map(&:problem)
    end

    test "reports a dead end on a flow of the kind a host actually builds" do
      document = { "entry" => "ask",
                   "nodes" => [ { "id" => "ask", "type" => "question", "question" => "Budget?",
                                  "answers" => [ { "value" => "high" } ] } ],
                   "edges" => [] }

      assert_includes violations(document, EasyFlow.registry, checks: EasyFlow.checks).map(&:problem), :dead_end
    end

    def beginning_registry
      Registry.new.tap do |registry|
        registry.register(StepType.define(:plain) { })
        registry.register(StepType.define(:go) { begins_here })
      end
    end

    def beginnings(document)
      built = Document.new(document, registry: beginning_registry)

      Validator.new(built, registry: beginning_registry, checks: []).violations
    end

    test "reports a flow with more than one beginning" do
      document = { "nodes" => [ { "id" => "g", "type" => "go" }, { "id" => "h", "type" => "go" } ],
                   "edges" => [ { "from" => "g", "to" => "h" } ] }

      assert_includes beginnings(document).map(&:problem), :many_beginnings
    end

    test "reports a step leading into where the flow begins" do
      document = { "nodes" => [ { "id" => "g", "type" => "go" }, { "id" => "a", "type" => "plain" } ],
                   "edges" => [ { "from" => "g", "to" => "a" }, { "from" => "a", "to" => "g" } ] }

      assert_includes beginnings(document).map(&:problem), :before_the_beginning
    end
  end
end
