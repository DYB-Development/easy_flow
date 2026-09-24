require "test_helper"

module EasyFlow
  class RunTest < ActiveSupport::TestCase
    test "going back removes the last answer along the path, not the last in list order" do
      flow = Definition.create!(host: "dummy", slug: "jump")
      flow.definition_versions.create!(number: 1, definition: flowing({
        "slug" => "jump", "entry" => "a",
        "nodes" => [
          { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] },
          { "id" => "b", "type" => "question", "text" => "B", "options" => [ "x" ] },
          { "id" => "c", "type" => "question", "text" => "C", "options" => [ "x" ] }
        ],
        "edges" => [ { "from" => "a", "to" => "c" }, { "from" => "c", "to" => "b" } ]
      }))
      flow.publish_version(flow.definition_versions.first)
      response = Run.start(flow)
      response.update!(recorded: { a: "x", c: "x", b: "x" })

      response.discard_last

      assert_equal({ a: "x", c: "x" }, response.reload.recorded)
    end

    test "pins to the flow's current definition version when started" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      flow.publish_version(version)

      response = Run.start(flow)

      assert_equal version, response.definition_version
    end

    test "pins to the newer version once that version is published" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      flow.publish_version(flow.definition_versions.first)
      republished = flow.definition_versions.create!(number: 2, definition: { "slug" => "demo" })
      flow.publish_version(republished)

      response = Run.start(flow.reload)

      assert_equal republished, response.definition_version
    end

    test "leaves an earlier response pinned to the version it began on" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      began_on = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      flow.publish_version(began_on)
      response = Run.start(flow)

      flow.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      assert_equal began_on, response.reload.definition_version
    end

    test "takes an owner of any type the host application supplies" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      flow.publish_version(version)
      owner = Definition.create!(host: "dummy", slug: "owning-record")

      response = flow.runs.create!(definition_version: version, owner: owner)

      assert_equal owner, response.reload.owner
    end

    test "is valid with no owner at all" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
      flow.publish_version(version)

      response = flow.runs.build(definition_version: version, owner: nil)

      assert response.valid?
    end

    test "records an answer into its stored answers" do
      response = Run.start(flow_with_a_version)

      response.record(:pick, "a")

      assert_equal({ pick: "a" }, response.recorded)
    end

    test "reads its answers back from the database with symbol keys" do
      response = Run.start(flow_with_a_version)
      response.record(:pick, "a")

      assert_equal({ pick: "a" }, response.reload.recorded)
    end

    test "reads the steps of the flow it is pinned to" do
      run = Run.start(easy_flow_definitions(:db_guide))

      assert_includes run.pinned_definition["nodes"].map { |node| node["id"] }, "pick"
    end

    test "discards the answer it last recorded" do
      response = Run.start(easy_flow_definitions(:db_guide))
      response.record(:pick, "a")

      response.discard_last

      assert_empty response.reload.recorded
    end

    private

    def flow_with_a_version
      Definition.create!(host: "dummy", slug: "demo").tap do |flow|
        version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })
        flow.publish_version(version)
      end
    end

    test "stays on the flow it was pinned to when the weights change" do
      flow = weighted_flow
      run = Run.start(flow)
      flow.record_definition(flowing("slug" => "scored", "entry" => "budget", "edges" => [],
        "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                       "options" => [ { "value" => "high", "weight" => 99 } ] } ]))

      assert_equal 5, run.reload.pinned_definition["nodes"].first["options"].first["weight"]
    end

    def weighted_flow
      Definition.create!(host: "dummy", slug: "scored").tap do |flow|
        flow.record_definition("slug" => "scored", "entry" => "budget", "edges" => [],
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                         "options" => [ { "value" => "high", "weight" => 5 } ] } ])
        flow.publish
      end
    end

    test "a run starts on the live version" do
      flow = Definition.create!(host: "dummy", slug: "demo", document: { "slug" => "demo" })
      flow.publish

      run = Run.start(flow)

      assert_equal flow.live_version, run.definition_version
    end

    def pinned
      flow = Definition.create!(host: "dummy", slug: "pinned")
      flow.record_definition(flowing(
        "slug" => "pinned", "entry" => "a",
        "nodes" => [ { "id" => "a", "type" => "question", "question" => "A?",
                       "answers" => [ { "value" => "yes" } ] },
                     { "id" => "b", "type" => "question", "question" => "B?",
                       "answers" => [ { "value" => "yes" } ] },
                     { "id" => "end", "type" => "terminal" } ],
        "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "end" } ]))
      flow.publish
      Run.start(flow)
    end

    test "reads the flow it was pinned to" do
      assert_equal "pinned", pinned.pinned_definition["slug"]
    end

    test "waits at the first step nothing has been recorded for" do
      assert_equal "a", pinned.next_step({}).id
    end

    test "moves on once a step has been recorded" do
      assert_equal "b", pinned.next_step("a" => "yes").id
    end

    test "reports the steps walked so far" do
      assert_equal({ "a" => "yes" }, pinned.walked("a" => "yes"))
    end
  end
end
