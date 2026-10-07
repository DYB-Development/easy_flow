require "test_helper"

module EasyFlow
  class RunTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

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

    test "gives the output its flow wrote when it ended" do
      flow = Definition.create!(host: "dummy", slug: "sale")
      flow.definition_versions.create!(number: 1, definition: flowing({
        "slug" => "sale", "entry" => "a",
        "nodes" => [
          { "id" => "a", "type" => "question", "text" => "Buy?", "options" => [ "yes" ] },
          { "id" => "done", "type" => "terminal", "output" => "bought" }
        ],
        "edges" => [ { "from" => "a", "to" => "done" } ]
      }))
      flow.publish_version(flow.definition_versions.first)
      response = Run.start(flow)
      response.record("a", "yes")

      assert_equal "bought", response.output
    end

    test "pins to a chosen published version when started on one" do
      flow = Definition.create!(host: "dummy", slug: "choice")
      first = flow.definition_versions.create!(number: 1, definition: { "slug" => "choice" })
      flow.publish_version(first)
      flow.publish_version(flow.definition_versions.create!(number: 2, definition: { "slug" => "choice" }))

      assert_equal first, Run.start(flow, version: first).definition_version
    end

    test "refuses to start on a version the flow never published" do
      flow = Definition.create!(host: "dummy", slug: "draft")
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => "draft" }))
      draft = flow.definition_versions.create!(number: 2, definition: { "slug" => "draft" })

      assert_raises(ActiveRecord::RecordInvalid) { Run.start(flow, version: draft) }
    end

    test "refuses to start on a version of another flow" do
      flow = Definition.create!(host: "dummy", slug: "mine")
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => "mine" }))
      other = Definition.create!(host: "dummy", slug: "theirs")
      theirs = other.definition_versions.create!(number: 1, definition: { "slug" => "theirs" })
      other.publish_version(theirs)

      assert_raises(ActiveRecord::RecordInvalid) { Run.start(flow, version: theirs) }
    end

    test "an inner run says which run started it and at which step" do
      flow = Definition.create!(host: "dummy", slug: "nested")
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => "nested" }))
      parent = Run.start(flow)

      inner = Run.start(flow).tap { |run| run.update!(parent_run: parent, parent_step: "inner") }

      assert_equal [ parent, "inner" ], [ inner.reload.parent_run, inner.parent_step ]
    end

    def published(slug, nodes:, edges:, number: 1)
      Definition.find_or_create_by!(host: "dummy", slug: slug).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: number, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def inner_flow
      @inner_flow ||= published("inner",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "ask", "type" => "question", "text" => "Buy?", "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal", "output" => "bought" } ],
        edges: [ { "from" => "start", "to" => "ask" }, { "from" => "ask", "to" => "done" } ])
    end

    def parent_flow
      @parent_flow ||= published("parent",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "offer", "type" => "flow_step", "flow" => inner_flow.id.to_s, "version" => 1 }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "offer" }, { "from" => "offer", "to" => "done", "on" => "bought" } ])
    end

    test "a stored run that reaches a Flow step starts one run of the chosen flow on the chosen version" do
      parent = Run.start(parent_flow)

      parent.advance

      assert_equal [ [ inner_flow, 1 ] ], parent.inner_runs.map { |inner| [ inner.flow, inner.definition_version.number ] }
    end

    test "advancing a parent run again while it waits starts no second inner run" do
      parent = Run.start(parent_flow)
      parent.advance

      parent.advance

      assert_equal 1, parent.inner_runs.count
    end

    test "an inner run's steps that act without a visitor run as soon as it starts" do
      acting = published("acting",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "work", "type" => "deliver", "message" => "Hi" }, { "id" => "ask", "type" => "question", "text" => "Buy?", "options" => [ "yes" ] } ],
        edges: [ { "from" => "start", "to" => "work" }, { "from" => "work", "to" => "ask" } ])
      parent = Run.start(published("handing", nodes: [ { "id" => "start", "type" => "start" }, { "id" => "offer", "type" => "flow_step", "flow" => acting.id.to_s, "version" => 1 } ],
                                              edges: [ { "from" => "start", "to" => "offer" } ]))

      parent.advance

      assert_equal({ work: false }, parent.inner_runs.sole.recorded)
    end

    test "trying a parent flow without saving it stops at the Flow step and starts no run" do
      flow = parent_flow

      assert_no_difference -> { Run.count } do
        Runner.new(flow.live_definition).run(Progress::Loose.new(flow, {}))
      end
    end

    test "an inner run that reaches an End step records that step's output in its parent at the Flow step" do
      parent = Run.start(parent_flow)
      parent.advance
      inner = parent.inner_runs.sole
      inner.record(:ask, "yes")

      inner.advance

      assert_equal "bought", parent.reload.recorded[:offer]
    end

    test "an inner run that hands its output to its parent queues a job to move the parent on" do
      parent = Run.start(parent_flow)
      parent.advance
      inner = parent.inner_runs.sole
      inner.record(:ask, "yes")

      assert_enqueued_with(job: AdvanceParentJob, args: [ parent, "offer" ]) { inner.advance }
    end

    test "the job moves the parent on along the connection named after the recorded output" do
      parent = Run.start(published("continuing",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "offer", "type" => "flow_step", "flow" => inner_flow.id.to_s, "version" => 1 },
                 { "id" => "thank", "type" => "deliver", "message" => "Thanks" }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "offer" }, { "from" => "offer", "to" => "thank", "on" => "bought" }, { "from" => "thank", "to" => "done" } ]))
      parent.advance
      parent.inner_runs.sole.tap { |inner| inner.record(:ask, "yes") }.advance

      perform_enqueued_jobs

      assert_equal({ offer: "bought", thank: false }, parent.reload.recorded)
    end

    test "a finished inner run advanced again hands its output back only once" do
      parent = Run.start(parent_flow)
      parent.advance
      inner = parent.inner_runs.sole.tap { |run| run.record(:ask, "yes") }
      inner.advance

      assert_no_enqueued_jobs(only: AdvanceParentJob) { inner.advance }
    end

    test "a parent run says which inner run it is waiting on" do
      parent = Run.start(parent_flow)
      parent.advance

      assert_equal parent.inner_runs.sole, parent.waiting_on
    end

    test "an inner run belongs to the same owner as the parent run that started it" do
      customer = ::Customer.create!(name: "Sam")
      parent = Run.start(parent_flow).tap { |run| run.update!(owner: customer) }

      parent.advance

      assert_equal customer, parent.inner_runs.sole.owner
    end

    test "an inner run that ends with no output records nothing in its parent" do
      silent = published("silent", nodes: [ { "id" => "start", "type" => "start" }, { "id" => "done", "type" => "terminal" } ],
                                   edges: [ { "from" => "start", "to" => "done" } ])
      parent = Run.start(published("hushed", nodes: [ { "id" => "start", "type" => "start" }, { "id" => "offer", "type" => "flow_step", "flow" => silent.id.to_s, "version" => 1 } ],
                                             edges: [ { "from" => "start", "to" => "offer" } ]))

      parent.advance

      assert_not parent.reload.recorded.key?(:offer)
    end

    test "the job fails with an error naming the Flow step when nothing was recorded there" do
      parent = Run.start(parent_flow)
      parent.advance

      error = assert_raises(InnerFlowError) { AdvanceParentJob.perform_now(parent, "offer") }

      assert_includes error.message, "offer"
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

    test "advancing a run carries it past a waiting step once what it waits for has happened" do
      flow = Definition.create!(host: "dummy", slug: "awaiting").tap do |built|
        built.record_definition(flowing({ "slug" => "awaiting", "entry" => "hold",
          "nodes" => [ { "id" => "hold", "type" => "await_signal" },
                       { "id" => "after", "type" => "question", "question" => "Next?", "answers" => [ { "value" => "ok" } ] } ],
          "edges" => [ { "from" => "hold", "to" => "after" } ] }))
        built.publish
      end
      run = Run.start(flow)
      ::Steps::AwaitSignal.signalled = true

      run.advance

      assert_equal({ hold: true }, run.reload.recorded)
    ensure
      ::Steps::AwaitSignal.signalled = false
    end
  end
end
