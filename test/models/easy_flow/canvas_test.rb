require "test_helper"

module EasyFlow
  class CanvasTest < ActiveSupport::TestCase
    def registry
      Registry.new.tap do |built|
        built.register(StepType.define(:ask) do
          step_name "Ask"
          output :answer, values: ->(node) { Array(node.config["options"]) }
          setting :text, type: :string
          setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer }
          names_by :text
        end)
        built.register(StepType.define(:switch) do
          step_name "Switch"
          setting :step, type: :previous_step
          output :choice, from: :step
          route { |node, state| state[node.config["step"]] }
        end)
        built.register(StepType.define(:stop) { step_name "End"; ends_here })
        built.register(StepType.define(:go) { step_name "Start"; begins_here })
        built.register(StepType.define(:branch) do
          step_name "Branch"
          setting :step, type: :previous_step
          setting :output, outputs_of: :step
          setting :answer, from: :output
          output :result, type: :boolean, values: [ true, false ]
          route { |_node, _state| true }
        end)
      end
    end

    def canvas(document)
      Canvas.new(Document.new(flowing(document)), registry: registry).to_h
    end

    def flow
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "ask", "text" => "Budget?" }, { "id" => "b", "type" => "branch" } ],
        "edges" => [ { "from" => "a", "to" => "b" } ] }
    end

    def switching
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "ask", "options" => [ { "value" => "high" }, { "value" => "low" } ] },
                     { "id" => "s", "type" => "switch", "step" => "a" } ],
        "edges" => [ { "from" => "a", "to" => "s" } ] }
    end

    def picking
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "ask", "text" => "Budget?", "options" => [ { "value" => "high" } ] },
                     { "id" => "b", "type" => "branch", "step" => "a", "output" => "answer" } ],
        "edges" => [ { "from" => "a", "to" => "b" } ] }
    end

    def side_by_side
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "ask" }, { "id" => "c", "type" => "ask" } ],
        "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" }, { "from" => "b", "to" => "c" } ] }
    end

    test "gives every node a row and a column" do
      placed = canvas(flow)["nodes"].map { |node| node.values_at("row", "column") }

      assert(placed.all? { |row, column| row.is_a?(Integer) && column.is_a?(Integer) })
    end

    test "labels a node from the field its type says names it" do
      assert_equal "Budget?", canvas(flow)["nodes"].find { |node| node["id"] == "a" }["label"]
    end

    test "falls back to the node id when its type names no field" do
      assert_equal "b", canvas(flow)["nodes"].find { |node| node["id"] == "b" }["label"]
    end

    test "carries every registered step type as a palette entry" do
      assert_equal [ "Ask", "Switch", "End", "Branch" ], canvas(flow)["palette"].map { |entry| entry["label"] }
    end

    test "carries what a palette entry's record field holds" do
      entry = canvas(flow)["palette"].first

      assert_equal({ "options" => { "value" => "string", "weight" => "integer" } }, entry["records"])
    end

    test "carries a palette entry's declared fields" do
      assert_equal("string", canvas(flow)["palette"].first["fields"]["text"])
    end

    def routed(document, from, to)
      canvas(document)["edges"].find { |edge| edge["source"] == from && edge["target"] == to }
    end

    def branching_flow
      { "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "branch" }, { "id" => "l", "type" => "ask" },
                     { "id" => "r", "type" => "ask" }, { "id" => "end", "type" => "ask" } ],
        "edges" => [ { "from" => "a", "to" => "l", "on" => true }, { "from" => "a", "to" => "r", "on" => false },
                     { "from" => "l", "to" => "end" }, { "from" => "r", "to" => "end" } ] }
    end

    test "a step leading to the one below it goes straight down" do
      edge = routed(flow, "a", "b")

      assert_equal [ "bottom", "top", "straight" ], edge.values_at("leaves", "enters", "route")
    end

    test "a branch leaves the bottom for each of its targets" do
      leaving = [ routed(branching_flow, "a", "l"), routed(branching_flow, "a", "r") ]

      assert_equal [ "bottom", "bottom" ], leaving.map { |edge| edge["leaves"] }
    end

    test "a branch lanes across into the top of its target" do
      assert_equal [ "top", "lane" ], routed(branching_flow, "a", "l").values_at("enters", "route")
    end

    test "a step merging across into a shared step takes the lane between rows" do
      assert_equal [ "bottom", "top", "lane" ], routed(branching_flow, "r", "end").values_at("leaves", "enters", "route")
    end

    test "a step rejoining one beside it goes straight across" do
      rejoining = { "entry" => "a",
                    "nodes" => [ { "id" => "a", "type" => "branch" }, { "id" => "l", "type" => "ask" }, { "id" => "r", "type" => "ask" } ],
                    "edges" => [ { "from" => "a", "to" => "l", "on" => "yes" }, { "from" => "a", "to" => "r", "on" => "no" },
                                 { "from" => "r", "to" => "l" } ] }

      assert_equal [ "left", "right", "straight" ], routed(rejoining, "r", "l").values_at("leaves", "enters", "route")
    end

    test "a step looping back up detours around" do
      looping = { "entry" => "a",
                  "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "ask" } ],
                  "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "a" } ] }

      assert_equal "detour", routed(looping, "b", "a")["route"]
    end

    test "carries the document's edges" do
      assert_equal [ [ "start", "a" ], [ "a", "b" ] ],
        canvas(flow)["edges"].reject { |edge| edge["placeholder"] }.map { |edge| [ edge["source"], edge["target"] ] }
    end

    test "carries the violations the document has" do
      stranded = flow.merge("nodes" => flow["nodes"] + [ { "id" => "loose", "type" => "ask" } ])

      assert_includes canvas(stranded)["violations"].map { |violation| violation["node"] }, "loose"
    end

    test "offers a step-naming setting the steps that come before that node" do
      assert_includes canvas(flow)["nodes"].find { |node| node["id"] == "b" }["choices"]["step"], { "value" => "a", "label" => "Budget?" }
    end

    test "offers a drawing setting the values the step it names outputs" do
      assert_equal [ { "value" => "high" } ], canvas(picking)["nodes"].find { |node| node["id"] == "b" }["choices"]["answer"]
    end

    test "gives a switching node a placeholder for each value the step it names outputs" do
      gaps = canvas(switching)["nodes"].select { |node| node["placeholder"] }

      assert_equal [ "high", "low" ], gaps.map { |node| node["label"] }
    end

    test "offers an output-naming setting the outputs of the step it reads" do
      assert_equal [ { "value" => "answer", "label" => "Answer" } ],
        canvas(picking)["nodes"].find { |node| node["id"] == "b" }["choices"]["output"]
    end

    test "says of a node that the flow ends there" do
      document = { "entry" => "a",
                   "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "z", "type" => "stop" } ],
                   "edges" => [ { "from" => "a", "to" => "z" } ] }

      assert canvas(document)["nodes"].last["ends_here"]
    end

    test "offers no way to add a second beginning" do
      document = { "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "z", "type" => "stop" } ],
                   "edges" => [ { "from" => "a", "to" => "z" } ] }

      assert_equal [ "Ask", "Switch", "End", "Branch" ], canvas(document)["palette"].map { |entry| entry["label"] }
    end

    test "says of a node that the flow begins there" do
      document = { "nodes" => [ { "id" => "g", "type" => "go" }, { "id" => "a", "type" => "ask" } ],
                   "edges" => [ { "from" => "g", "to" => "a" } ] }

      assert canvas(document)["nodes"].find { |node| node["id"] == "g" }["begins_here"]
    end

    test "says of a node that nothing in the flow leads to it" do
      document = { "nodes" => [ { "id" => "g", "type" => "go" }, { "id" => "a", "type" => "ask" },
                                { "id" => "adrift", "type" => "ask" } ],
                   "edges" => [ { "from" => "g", "to" => "a" } ] }
      built = Document.new(document, registry: registry)

      drawn = Canvas.new(built, registry: registry).to_h["nodes"].reject { |node| node["placeholder"] }

      assert_equal [ false, false, true ], drawn.map { |node| node["loose"] }
    end

    test "draws a placeholder where a result has nowhere to go" do
      document = { "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "branch", "step" => "a" } ],
                   "edges" => [ { "from" => "a", "to" => "b" } ] }
      built = Document.new(document, registry: registry)
      drawn = Canvas.new(built, registry: registry).to_h

      assert_equal [ "true", "false" ], drawn["nodes"].select { |node| node["placeholder"] }.map { |node| node["label"] }
    end

    test "leads to each placeholder from the step whose result it is" do
      document = { "nodes" => [ { "id" => "a", "type" => "ask" }, { "id" => "b", "type" => "branch", "step" => "a" } ],
                   "edges" => [ { "from" => "a", "to" => "b" } ] }
      built = Document.new(document, registry: registry)
      drawn = Canvas.new(built, registry: registry).to_h

      assert_equal [ "b", "b" ], drawn["edges"].select { |edge| edge["placeholder"] }.map { |edge| edge["source"] }
    end

    test "draws a placeholder where a step leads nowhere at all" do
      document = { "nodes" => [ { "id" => "a", "type" => "ask" } ], "edges" => [] }
      built = Document.new(document, registry: registry)
      drawn = Canvas.new(built, registry: registry).to_h

      assert_equal [ "a--" ], drawn["nodes"].select { |node| node["placeholder"] }.map { |node| node["id"] }
    end

    test "draws no placeholder after a step the flow ends at" do
      document = { "nodes" => [ { "id" => "z", "type" => "stop" } ], "edges" => [] }
      built = Document.new(document, registry: registry)
      drawn = Canvas.new(built, registry: registry).to_h

      assert_empty drawn["nodes"].select { |node| node["placeholder"] }
    end

    test "draws no placeholder after a step waiting outside the flow" do
      document = { "nodes" => [ { "id" => "g", "type" => "go" }, { "id" => "adrift", "type" => "ask" } ],
                   "edges" => [] }
      built = Document.new(document, registry: registry)
      gaps = Canvas.new(built, registry: registry).to_h["nodes"].select { |node| node["placeholder"] }

      assert_equal [ "g" ], gaps.map { |node| node["from"] }
    end

    test "labels a connection with the result it leaves on, as words" do
      document = { "nodes" => [ { "id" => "a", "type" => "branch" }, { "id" => "l", "type" => "ask" },
                                { "id" => "r", "type" => "ask" } ],
                   "edges" => [ { "from" => "a", "to" => "l", "on" => true },
                                { "from" => "a", "to" => "r", "on" => false } ] }
      built = Document.new(document, registry: registry)

      labelled = Canvas.new(built, registry: registry).to_h["edges"].filter_map { |edge| edge["label"] }

      assert_equal [ "true", "false" ], labelled
    end
  end
end
