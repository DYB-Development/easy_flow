require "test_helper"

module EasyFlow
  class PlayFlowsTest < ActiveSupport::TestCase
    def published(slug, title: nil, host: "dummy", owner: nil, nodes: [ { "id" => "start", "type" => "start" }, { "id" => "done", "type" => "terminal" } ], edges: [ { "from" => "start", "to" => "done" } ])
      Definition.create!(host: host, slug: slug, title: title, owner: owner).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def quizzes
      @quizzes ||= [ published("history", title: "History"), published("science", title: "Science") ]
    end

    def node
      Node.new(id: "play", type: "play_flows", config: { "flows" => quizzes.map { |quiz| quiz.id.to_s } })
    end

    def event_run
      @event_run ||= Run.start(published("event",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "play", "type" => "play_flows", "flows" => quizzes.map { |quiz| quiz.id.to_s } }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "play" }, { "from" => "play", "to" => "done" } ]))
    end

    def event(flows = quizzes.map { |quiz| quiz.id.to_s })
      Document.new({ "entry" => "start",
        "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "play", "type" => "play_flows", "flows" => flows },
                     { "id" => "after", "type" => "question", "text" => "Again?", "options" => [ "no" ] } ],
        "edges" => [ { "from" => "start", "to" => "play" }, { "from" => "play", "to" => "after" } ] })
    end

    def offered(at = node)
      PlayFlows.step_type.display_of(at, event_run).choices.map(&:label)
    end

    test "is registered for a flow to use, named Play flows" do
      assert_equal "Play flows", EasyFlow.registry.fetch("play_flows").step_name
    end

    test "takes the flows it offers, chosen from the flows the canvas offers" do
      assert_equal :flows, PlayFlows.step_type.settings.fields[:flows]
    end

    test "takes the question it asks the visitor above the flows it offers" do
      assert_equal :string, PlayFlows.step_type.settings.fields[:question]
    end

    test "offers a visitor who reaches it each flow it lists" do
      assert_equal %w[History Science], offered
    end

    test "leaves out a flow the visitor already played at an earlier visit" do
      Run.start(quizzes.first).update!(parent_run: event_run, parent_step: "play")

      assert_equal %w[Science], offered(node.with(id: "play@2"))
    end

    test "leaves out a listed flow that another owner owns" do
      ours = Customer.create!(name: "Ours")
      listed = [ published("ours", title: "Ours", host: "owned", owner: ours), published("theirs", title: "Theirs", host: "owned", owner: Customer.create!(name: "Theirs")) ]
      play = Node.new(id: "play", type: "play_flows", config: { "flows" => listed.map { |quiz| quiz.id.to_s } })
      run = Run.start(published("owned-event", host: "owned", owner: ours))

      assert_equal %w[Ours], PlayFlows.step_type.display_of(play, run).choices.map(&:label)
    end

    test "holds a run that reaches it until the visitor picks a flow" do
      assert_equal "play", Digest.new(event).next_step({}).id
    end

    test "comes back for the next pick while a listed flow is still to be played" do
      assert_equal "play@2", Digest.new(event).next_step({ "play" => "ended" }).id
    end

    test "moves on to its next step once every listed flow has been played" do
      assert_equal "after", Digest.new(event).next_step({ "play" => "ended", "play@2" => "ended" }).id
    end

    test "plays the flow a visitor picks as an inner run of the visitor's run at that visit" do
      Progress::Kept.new(event_run).record("play", quizzes.last.id.to_s)

      assert_equal quizzes.last, event_run.inner_runs.find_by(parent_step: "play")&.flow
    end

    test "plays nothing when a visitor picks a flow already played" do
      Run.start(quizzes.first).update!(parent_run: event_run, parent_step: "play")

      Progress::Kept.new(event_run).record("play@2", quizzes.first.id.to_s)

      assert_not event_run.inner_runs.exists?(parent_step: "play@2")
    end

    test "is named by the question it asks" do
      assert_equal "Which quiz next?", PlayFlows.step_type.name_of(Node.new(id: "play", type: "play_flows", config: { "question" => "Which quiz next?" }))
    end

    test "cannot run without the flows it offers" do
      assert_includes PlayFlows.step_type.settings.required, :flows
    end

    test "plays nothing more at a visit where a picked flow is already playing" do
      Run.start(quizzes.first).update!(parent_run: event_run, parent_step: "play")

      Progress::Kept.new(event_run).record("play", quizzes.last.id.to_s)

      assert_equal 1, event_run.inner_runs.where(parent_step: "play").count
    end

    test "moves on once every listed flow that still exists has been played" do
      assert_equal "after", Digest.new(event([ quizzes.first.id.to_s, "0" ])).next_step({ "play" => "ended" }).id
    end
  end
end
