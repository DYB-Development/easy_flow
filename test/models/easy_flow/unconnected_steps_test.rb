require "test_helper"

module EasyFlow
  class UnconnectedStepsTest < ActiveSupport::TestCase
    def asking(id, **config)
      { "id" => id, "type" => "question", "question" => id, "answers" => [ { "value" => "yes" } ] }.merge(config.transform_keys(&:to_s))
    end

    def checked(nodes, edges = [])
      UnconnectedSteps.new(Document.new(flowing({ "entry" => "a", "nodes" => [ asking("a"), { "id" => "end", "type" => "terminal" } ] + nodes,
                                                  "edges" => [ { "from" => "a", "to" => "end" } ] + edges })))
    end

    test "a problem only on a step being removed is no objection" do
      assert_empty checked([ { "id" => "aside", "type" => "question" } ]).objections
    end

    test "a problem on a step that stays is an objection" do
      unsettled = UnconnectedSteps.new(Document.new(flowing({ "entry" => "a", "nodes" => [ { "id" => "a", "type" => "question" }, { "id" => "end", "type" => "terminal" }, asking("aside") ],
                                                              "edges" => [ { "from" => "a", "to" => "end" } ] })))

      assert_includes unsettled.objections.map(&:node), "a"
    end

    test "a connection from a removed step into the beginning is no objection" do
      assert_empty checked([ asking("aside") ], [ { "from" => "aside", "to" => "start" } ]).objections
    end

    test "a step that stays reading a removed step in a list entry is an objection" do
      reading = { "id" => "gate", "type" => "all_or_any", "join" => "all of",
                  "comparisons" => [ { "step" => "aside", "output" => "answer", "comparison" => "equal to" } ] }
      unsettled = UnconnectedSteps.new(Document.new(flowing({ "entry" => "gate", "nodes" => [ reading, { "id" => "end", "type" => "terminal" }, asking("aside") ],
                                                              "edges" => [ { "from" => "gate", "to" => "end", "on" => true }, { "from" => "gate", "to" => "end", "on" => false } ] })))

      assert_equal [ :reading_an_unconnected_step ], unsettled.objections.map(&:problem)
    end

    test "names each step that would be removed by its id and label" do
      assert_equal [ { "id" => "aside", "label" => "Aside" } ], checked([ asking("aside", question: "Aside") ]).named
    end

    test "the removal is accepted only when it names the same steps" do
      assert_equal [ true, false ], [ checked([ asking("aside") ]).accepted?([ "aside" ]), checked([ asking("aside"), asking("other") ]).accepted?([ "aside" ]) ]
    end
  end
end
