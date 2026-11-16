require "test_helper"

module EasyFlow
  class DocumentTest < ActiveSupport::TestCase
    def foreign
      @foreign ||= Registry.new.tap do |built|
        built.register(StepType.define(:opening) { begins_here })
        built.register(StepType.define(:draft) { awaits_input })
        built.register(StepType.define(:repeat) { holds_steps })
      end
    end

    def drafting
      Document.new({ "nodes" => [ { "id" => "o", "type" => "opening" }, { "id" => "a", "type" => "draft" } ],
                     "edges" => [ { "from" => "o", "to" => "a" } ] }, registry: foreign)
    end

    def grouping
      Document.new({ "nodes" => [ { "id" => "o", "type" => "opening" }, { "id" => "loop", "type" => "repeat" }, { "id" => "a", "type" => "draft" } ],
                     "edges" => [ { "from" => "o", "to" => "loop" }, { "from" => "loop", "to" => "a" } ] }, registry: foreign)
    end

    def held_by(document, id)
      document.to_h["nodes"].find { |node| node["id"] == id }["holds"]
    end

    test "puts a step into the group step it is moved into" do
      assert_equal [ "a" ], held_by(grouping.group("a", into: "loop"), "loop")
    end

    test "takes a step out of the group step that held it when it is moved into none" do
      assert_empty held_by(grouping.group("a", into: "loop").group("a", into: nil), "loop")
    end

    test "no group step holds a step once that step is removed" do
      assert_empty held_by(grouping.group("a", into: "loop").remove("a"), "loop")
    end

    test "still knows where it begins after it is edited" do
      assert_equal "o", drafting.add({ "id" => "b", "type" => "draft" }).entry
    end

    test "reports what stays reachable from the entry when a step is left out" do
      document = Document.new(flowing({ "entry" => "a",
                                        "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" } ],
                                        "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ] }))

      assert_equal [ "start", "a" ], document.reachable(without: "b")
    end

    test "has no nodes when the document declares none" do
      assert_empty Document.new({}).nodes
    end

    test "has no edges when the document declares none" do
      assert_empty Document.new({}).edges
    end

    test "has no edges leaving a node when the document declares none" do
      assert_empty Document.new({}).edges_from("a")
    end

    test "finds the edges leaving a node" do
      document = Document.new({ "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ] })

      assert_equal [ "b" ], document.edges_from("a").map(&:to)
    end

    test "begins at the step whose type says a flow begins there" do
      document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question" },
                                             { "id" => "go", "type" => "start" } ] })

      assert_equal "go", document.entry
    end

    test "begins nowhere when no step says a flow begins there" do
      assert_nil Document.new({ "nodes" => [ { "id" => "a", "type" => "question" } ] }).entry
    end

    test "finds a node by its id" do
      document = Document.new({ "nodes" => [ { "id" => "a" }, { "id" => "b" } ] })

      assert_equal "b", document.node("b").id
    end

    test "finds no node for an id the document does not carry" do
      document = Document.new({ "nodes" => [ { "id" => "a" } ] })

      assert_nil document.node("missing")
    end

    test "exposes an edge's source and target" do
      document = Document.new({ "edges" => [ { "from" => "a", "to" => "b" } ] })

      assert_equal [ [ "a", "b" ] ], document.edges.map { |edge| [ edge.from, edge.to ] }
    end

    test "exposes the named output port an edge leaves by" do
      document = Document.new({ "edges" => [ { "from" => "a", "to" => "b", "on" => "yes" } ] })

      assert_equal "yes", document.edges.first.on
    end

    test "leaves the port empty when an edge names none" do
      document = Document.new({ "edges" => [ { "from" => "a", "to" => "b" } ] })

      assert_nil document.edges.first.on
    end

    test "exposes a node's type" do
      document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question" } ] })

      assert_equal "question", document.nodes.first.type
    end

    test "keeps everything else on a node as its configuration" do
      document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question", "text" => "Budget?" } ] })

      assert_equal({ "text" => "Budget?" }, document.nodes.first.config)
    end

    test "exposes the id of each node" do
      document = Document.new({ "nodes" => [ { "id" => "a", "type" => "question" } ] })

      assert_equal [ "a" ], document.nodes.map(&:id)
    end

    def with_one_left_to_the_side
      Document.new(flowing({ "entry" => "a",
                             "nodes" => [ { "id" => "a", "type" => "question" }, { "id" => "aside", "type" => "question" } ],
                             "edges" => [ { "from" => "aside", "to" => "a" } ] }))
    end

    test "names the steps the flow does not reach as unconnected" do
      assert_equal [ "aside" ], with_one_left_to_the_side.unconnected
    end

    test "does not count a second beginning as unconnected" do
      second = Document.new(flowing({ "nodes" => [ { "id" => "again", "type" => "start" } ] }))

      assert_empty second.unconnected
    end

    test "taking steps out drops them and every connection touching them without joining what they connected" do
      assert_equal [ { "from" => "start", "to" => "a" } ], with_one_left_to_the_side.without([ "aside" ]).to_h["edges"]
    end
  end
end
