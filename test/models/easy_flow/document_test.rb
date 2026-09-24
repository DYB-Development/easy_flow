require "test_helper"

module EasyFlow
  class DocumentTest < ActiveSupport::TestCase
    def foreign
      @foreign ||= Registry.new.tap do |built|
        built.register(StepType.define(:opening) { begins_here })
        built.register(StepType.define(:draft) { awaits_input })
      end
    end

    def drafting
      Document.new({ "nodes" => [ { "id" => "o", "type" => "opening" }, { "id" => "a", "type" => "draft" } ],
                     "edges" => [ { "from" => "o", "to" => "a" } ] }, registry: foreign)
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
  end
end
