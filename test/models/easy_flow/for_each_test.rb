require "test_helper"

module EasyFlow
  class ForEachTest < ActiveSupport::TestCase
    def registry
      @registry ||= Registry.new.tap do |built|
        built.register(Start.step_type)
        built.register(ForEach.step_type)
        built.register(StepType.define(:ask) { awaits_input })
        built.register(StepType.define(:stamp) { process { |node, _state| "stamped #{node.id}" } })
        built.register(StepType.define(:reported) do
          awaits_input
          output :result, values: %w[passed failed retry]
          route { |node, state| state[node.id]["result"] }
        end)
      end
    end

    def drawing
      { "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "outline", "type" => "ask" },
                     { "id" => "variants", "type" => "for_each", "list" => "outline.variants", "holds" => [ "write" ] },
                     { "id" => "write", "type" => "ask" }, { "id" => "after", "type" => "ask" } ],
        "edges" => [ { "from" => "start", "to" => "outline" }, { "from" => "outline", "to" => "variants" },
                     { "from" => "variants", "to" => "write" }, { "from" => "write", "to" => "after" } ] }
    end

    def digest(document = drawing)
      Digest.new(Document.new(document, registry: registry), registry: registry)
    end

    def retrying
      drawing.merge("nodes" => drawing["nodes"].map { |node| node["id"] == "write" ? node.merge("type" => "reported") : node },
                    "edges" => drawing["edges"].map { |edge| edge["from"] == "write" ? edge.merge("on" => "passed") : edge } + [ { "from" => "write", "to" => "write", "on" => "retry" } ])
    end

    def failing
      retried = retrying
      retried.merge("nodes" => retried["nodes"].map { |node| node["id"] == "variants" ? node.merge("holds" => %w[write fix]) : node } + [ { "id" => "fix", "type" => "ask" } ],
                    "edges" => retried["edges"] + [ { "from" => "write", "to" => "fix", "on" => "failed" }, { "from" => "fix", "to" => "after" } ])
    end

    def advanced(document, state)
      progress = Class.new(Progress::Loose) { define_method(:saved?) { true } }.new(nil, state, document)
      Runner.new(document, registry: registry).run(progress)
      progress.recorded
    end

    def outlined
      { "outline" => { "variants" => %w[short long plain] } }
    end

    def stored_run
      flow = Definition.create!(host: "dummy", slug: "per-item", persists: :each_step)
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: drawing.merge("slug" => "per-item", "nodes" => drawing["nodes"].map { |node| node["type"] == "ask" ? node.merge("type" => "question") : node })))
      Run.start(flow).tap { |run| run.record("outline", outlined["outline"]) }
    end

    test "a for_each step holds steps and offers a list, a concurrency and an item-failure rule" do
      step_type = ForEach.step_type

      assert_equal [ true, { list: :string, concurrency: :integer, on_item_failure: :select } ], [ step_type.holds_steps?, step_type.settings.fields ]
    end

    test "walks its held steps once for each item of the list, one item after another in list order" do
      reached = [ outlined, outlined.merge("write@item1" => "a"), outlined.merge("write@item1" => "a", "write@item2" => "b") ]

      assert_equal %w[write@item1 write@item2 write@item3], reached.map { |state| digest.next_step(state).id }
    end

    test "records each item's visit of a held step under its item number with its own value" do
      run = stored_run
      %w[short-copy long-copy plain-copy].each { |copy| run.record(run.next_step(run.recorded).id, copy) }

      assert_equal({ "write@item1": "short-copy", "write@item2": "long-copy", "write@item3": "plain-copy" }, run.reload.recorded.slice(:"write@item1", :"write@item2", :"write@item3"))
    end

    test "records a held step retried inside one item as a further visit of that item and leaves the next item's visits as they were" do
      retried = outlined.merge("write@item1" => { "result" => "retry" })
      reached = [ retried, retried.merge("write@item1@2" => { "result" => "passed" }) ]

      assert_equal %w[write@item1@2 write@item2], reached.map { |state| digest(retrying).next_step(state).id }
    end

    test "gives a held step's input naming the current item that item's value from the list" do
      writing = Node.new(id: "write@item2", type: "ask", config: { "inputs" => [ { "name" => "variant", "current_item" => true } ] })

      assert_equal({ "variant" => "long" }, Inputs.values_of(writing, outlined, run: Struct.new(:digest).new(digest)))
    end

    test "gives a held step's input naming an earlier held step that step's output for the same item" do
      reviewing = Node.new(id: "review@item2", type: "ask", config: { "inputs" => [ { "name" => "title", "step" => "write", "output" => "title" } ] })
      written = outlined.merge("write@item1" => { "title" => "Short" }, "write@item2" => { "title" => "Long" }, "write@item1@2" => { "title" => "Shorter" })

      assert_equal({ "title" => "Long" }, Inputs.values_of(reviewing, written))
    end

    test "ends an item whose held step ended failed and starts the next item" do
      assert_equal "write@item2", digest(failing).next_step(outlined.merge("write@item1" => { "result" => "failed" })).id
    end

    test "records its result, each item's reported values and how many items passed and failed once every item has ended" do
      ended = outlined.merge("write@item1" => { "result" => "passed" }, "write@item2" => { "result" => "failed" }, "write@item3" => { "result" => "passed" })

      assert_equal({ "result" => "failed", "passed" => 2, "failed" => 1,
                     "items" => [ { "write" => { "result" => "passed" } }, { "write" => { "result" => "failed" } }, { "write" => { "result" => "passed" } } ] },
                   advanced(retrying, ended)[:variants])
    end

    test "offers a later step's inputs its result, items, passed and failed outputs" do
      assert_equal %w[result items passed failed], digest.outputs_of("variants").map { |output| output["value"] }
    end

    test "gives a step after the box its items, passed and failed outputs as inputs" do
      ended = advanced(retrying, outlined.merge("write@item1" => { "result" => "passed" }, "write@item2" => { "result" => "failed" }, "write@item3" => { "result" => "passed" }))
      reading = Node.new(id: "after", type: "ask", config: { "inputs" => %w[items passed failed].map { |output| { "name" => output, "step" => "variants", "output" => output } } })

      assert_equal({ "items" => ended[:variants]["items"], "passed" => 2, "failed" => 1 }, Inputs.values_of(reading, ended.transform_keys(&:to_s), run: Struct.new(:digest).new(digest(retrying))))
    end

    test "records no items over an empty list and goes on to the step after the box" do
      ended = advanced(drawing, "outline" => { "variants" => [] })

      assert_equal [ [], "after" ], [ ended[:variants]["items"], digest.next_step(ended.transform_keys(&:to_s)).id ]
    end

    def concurrent(document = drawing, concurrency: 3)
      document.merge("nodes" => document["nodes"].map { |node| node["id"] == "variants" ? node.merge("concurrency" => concurrency) : node })
    end

    def five_outlined
      { "outline" => { "variants" => %w[a b c d e] } }
    end

    test "names the first held step of as many items as its concurrency allows as ready at once" do
      assert_equal %w[write@item1 write@item2 write@item3], digest(concurrent).ready_steps(five_outlined).map(&:id)
    end

    test "names the first held step of the next item as ready once one of the ready items ends" do
      assert_equal %w[write@item1 write@item3 write@item4], digest(concurrent).ready_steps(five_outlined.merge("write@item2" => "b")).map(&:id)
    end

    test "counts an item still running its held steps among the unfinished items its concurrency allows" do
      started = five_outlined.merge("write@item1" => { "result" => "retry" }, "write@item2" => { "result" => "retry" }, "write@item3" => { "result" => "retry" })

      assert_equal %w[write@item1@2 write@item2@2 write@item3@2], digest(concurrent(retrying)).ready_steps(started).map(&:id)
    end

    test "names one item's held step as ready at a time when no concurrency is set" do
      assert_equal [ "write@item1" ], digest.ready_steps(five_outlined).map(&:id)
    end

    test "runs an acting held step of a later ready item while an earlier ready item waits for its answer" do
      stamping = concurrent(drawing.merge("nodes" => drawing["nodes"].map { |node| node["id"] == "variants" ? node.merge("holds" => %w[write stamp]) : node } + [ { "id" => "stamp", "type" => "stamp" } ],
                                          "edges" => drawing["edges"].map { |edge| edge["from"] == "write" ? edge.merge("to" => "stamp") : edge } + [ { "from" => "stamp", "to" => "after" } ]), concurrency: 2)

      assert_equal "stamped stamp", advanced(stamping, five_outlined.merge("write@item2" => "b"))[:"stamp@item2"]
    end

    test "names only the run's next step as ready outside a for_each step" do
      run = stored_run.tap { |started| started.update!(recorded: {}) }

      assert_equal [ "outline" ], run.ready_steps(run.recorded).map(&:id)
    end

    def stopping(concurrency: 1)
      retried = concurrent(retrying, concurrency: concurrency)
      retried.merge("nodes" => retried["nodes"].map { |node| node["id"] == "variants" ? node.merge("on_item_failure" => "stop") : node } + [ { "id" => "rescue", "type" => "ask" } ],
                    "edges" => retried["edges"] + [ { "from" => "write", "to" => "rescue", "on" => "failed" } ])
    end

    test "starts no item after an item has failed when its rule is stop" do
      assert_equal [ "variants" ], digest(stopping).ready_steps(outlined.merge("write@item1" => { "result" => "failed" })).map(&:id)
    end

    test "lets an item already running end after another item has failed when its rule is stop" do
      running = outlined.merge("write@item1" => { "result" => "failed" }, "write@item2" => { "result" => "retry" })

      assert_equal [ "write@item2@2" ], digest(stopping(concurrency: 2)).ready_steps(running).map(&:id)
    end

    test "leaves the box on the failed held step's failed connection once the running items have ended under the stop rule" do
      ended = advanced(stopping, outlined.merge("write@item1" => { "result" => "failed" }))

      assert_equal "rescue", digest(stopping).next_step(ended.transform_keys(&:to_s)).id
    end

    test "records a failed result holding only the items that ran when stopped by a failed item" do
      assert_equal({ "result" => "failed", "items" => [ { "write" => { "result" => "failed" } } ], "passed" => 0, "failed" => 1 },
                   advanced(stopping, outlined.merge("write@item1" => { "result" => "failed" }))[:variants])
    end

    test "ends only the failed item and starts the next one when its rule is continue" do
      continuing = stopping.merge("nodes" => stopping["nodes"].map { |node| node["id"] == "variants" ? node.merge("on_item_failure" => "continue") : node })

      assert_equal [ "write@item2" ], digest(continuing).ready_steps(outlined.merge("write@item1" => { "result" => "failed" })).map(&:id)
    end

    test "refuses a run that keeps nothing at a held step as it refuses one at the for_each step" do
      assert_equal "Steps can only be run for each item in a flow that saves its runs.", Runner.new(drawing, registry: registry).unsaved_refusal(outlined)
    end
  end
end
