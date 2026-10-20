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

    def offered(at = node)
      PlayFlows.step_type.display_of(at, event_run).choices.map(&:label)
    end

    test "is registered for a flow to use, named Play flows" do
      assert_equal "Play flows", EasyFlow.registry.fetch("play_flows").step_name
    end

    test "takes the flows it offers, chosen from the flows the canvas offers" do
      assert_equal :flows, PlayFlows.step_type.settings.fields[:flows]
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
  end
end
