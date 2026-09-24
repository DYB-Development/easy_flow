require "test_helper"

module EasyFlow
  class EditsTest < ActiveSupport::TestCase
    def two_step_flow
      built({ "entry" => "a",
                     "nodes" => [ { "id" => "a", "type" => "plain" }, { "id" => "b", "type" => "plain" } ],
                     "edges" => [ { "from" => "a", "to" => "b" } ] })
    end

    def built(shape)
      Document.new(flowing(shape))
    end

    def endpoints(document)
      document.edges.map { |edge| [ edge.from, edge.to ] }
    end

    def three_step_flow
      built({ "entry" => "a",
                     "nodes" => [ { "id" => "a" }, { "id" => "x" }, { "id" => "b" } ],
                     "edges" => [ { "from" => "a", "to" => "x" }, { "from" => "x", "to" => "b" } ] })
    end

    test "moving a step splices it onto another edge" do
      document = built({ "entry" => "a",
                                "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" }, { "id" => "loose" } ],
                                "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "c" } ] })

      result = document.move("loose", on: [ "b", "c" ])

      assert_equal [ [ "start", "a" ], [ "a", "b" ], [ "b", "loose" ], [ "loose", "c" ] ], endpoints(result)
    end

    test "moving a step keeps its configuration" do
      document = built({ "entry" => "a",
                                "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "loose", "type" => "ask", "text" => "Kept" } ],
                                "edges" => [ { "from" => "a", "to" => "b" } ] })

      result = document.move("loose", on: [ "a", "b" ])

      assert_equal "Kept", result.node("loose").config["text"]
    end

    test "connecting two steps adds an edge between them" do
      result = two_step_flow.add({ "id" => "c", "type" => "plain" }).connect(from: "b", to: "c")

      assert_includes endpoints(result), [ "b", "c" ]
    end

    test "connecting can name the port the edge leaves by" do
      result = two_step_flow.add({ "id" => "c", "type" => "plain" }).connect(from: "b", to: "c", on: "yes")

      assert_equal "yes", result.edges_from("b").first.on
    end

    test "disconnecting removes the edge between two steps" do
      result = two_step_flow.disconnect(from: "a", to: "b")

      assert_equal [ [ "start", "a" ] ], endpoints(result)
    end

    test "configuring a step replaces its configuration" do
      result = two_step_flow.configure("a", { "text" => "Budget?" })

      assert_equal({ "text" => "Budget?" }, result.node("a").config)
    end

    test "configuring a step leaves its id and type alone" do
      result = two_step_flow.configure("a", { "text" => "Budget?" })

      assert_equal "plain", result.node("a").type
    end

    test "allows a step that nothing points at yet" do
      result = two_step_flow.add({ "id" => "loose", "type" => "plain" })

      assert_equal [ "start", "a", "b", "loose" ], result.nodes.map(&:id)
    end

    test "refuses an edit that would point an edge at nothing" do
      assert_raises InvalidEdit do
        three_step_flow.rewire(from: "a", to: "x", target: "ghost")
      end
    end

    test "leaves the document alone when it refuses an edit" do
      document = three_step_flow

      assert_raises(InvalidEdit) { document.rewire(from: "a", to: "x", target: "ghost") }

      assert_equal [ [ "start", "a" ], [ "a", "x" ], [ "x", "b" ] ], endpoints(document)
    end

    test "refuses an edit that would repeat a step's id" do
      assert_raises InvalidEdit do
        two_step_flow.add({ "id" => "a", "type" => "plain" })
      end
    end

    test "rewiring an edge sends it to a different step" do
      document = built({ "entry" => "a",
                                "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" }, { "id" => "d" } ],
                                "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "d" },
                                             { "from" => "b", "to" => "d" } ] })

      result = document.rewire(from: "b", to: "d", target: "c")

      assert_includes endpoints(result), [ "b", "c" ]
    end

    test "removing a step takes it out of the document's nodes" do
      assert_equal [ "start", "a", "b" ], three_step_flow.remove("x").nodes.map(&:id)
    end

    test "removing a step bridges the steps it sat between" do
      assert_equal [ [ "start", "a" ], [ "a", "b" ] ], endpoints(three_step_flow.remove("x"))
    end

    test "removing a step leaves the document it was given untouched" do
      document = three_step_flow

      document.remove("x")

      assert_equal [ "start", "a", "x", "b" ], document.nodes.map(&:id)
    end

    test "inserting a step adds it to the document's nodes" do
      result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

      assert_equal [ "start", "a", "b", "x" ], result.nodes.map(&:id)
    end

    test "inserting a step leaves the document it was given untouched" do
      document = two_step_flow

      document.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

      assert_equal [ [ "start", "a" ], [ "a", "b" ] ], endpoints(document)
    end

    test "inserting a step leaves edges it was not asked about alone" do
      document = built({ "entry" => "a",
                                "nodes" => [ { "id" => "a" }, { "id" => "b" }, { "id" => "c" } ],
                                "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "a", "to" => "c" } ] })

      result = document.insert({ "id" => "x" }, on: [ "a", "b" ])

      assert_includes endpoints(result), [ "a", "c" ]
    end

    test "inserting a step can name the port its own outgoing edge leaves by" do
      result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ], leaving: "yes")

      assert_equal "yes", result.edges_from("x").first.on
    end

    test "inserting a step leaves its outgoing edge unported by default" do
      result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

      assert_nil result.edges_from("x").first.on
    end

    test "inserting a step keeps the port the replaced edge left by" do
      document = built({ "entry" => "a",
                                "nodes" => [ { "id" => "a" }, { "id" => "b" } ],
                                "edges" => [ { "from" => "a", "to" => "b", "on" => "yes" } ] })

      result = document.insert({ "id" => "x" }, on: [ "a", "b" ])

      assert_equal "yes", result.edges_from("a").first.on
    end

    test "inserting a step on an edge replaces it with an edge in and an edge out" do
      result = two_step_flow.insert({ "id" => "x", "type" => "plain" }, on: [ "a", "b" ])

      assert_equal [ [ "start", "a" ], [ "a", "x" ], [ "x", "b" ] ], endpoints(result)
    end
  end
end
