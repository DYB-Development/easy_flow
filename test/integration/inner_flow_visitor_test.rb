require "test_helper"

module EasyFlow
  class InnerFlowVisitorTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    def published(slug, nodes:, edges:)
      Definition.create!(host: "dummy", slug: slug, persists: :each_step).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def inner_flow
      @inner_flow ||= published("inner",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "ask", "type" => "question", "text" => "Buy?", "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal", "output" => "bought" } ],
        edges: [ { "from" => "start", "to" => "ask" }, { "from" => "ask", "to" => "done" } ])
    end

    def parent_flow
      @parent_flow ||= published("parent",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "offer", "type" => "flow_step", "flow" => inner_flow.id.to_s, "version" => 1 },
                 { "id" => "after", "type" => "question", "text" => "Anything else?", "options" => [ "no" ] }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "offer" }, { "from" => "offer", "to" => "after", "on" => "bought" }, { "from" => "after", "to" => "done" } ])
    end

    test "a visitor whose run reaches a Flow step is taken to that step's inner run" do
      parent = Run.start(parent_flow)

      get easy_flow.run_path(parent)

      assert_redirected_to easy_flow.run_path(parent.inner_runs.sole)
    end

    test "a visitor who finishes an inner run is taken back to the parent run" do
      parent = Run.start(parent_flow).tap(&:advance)
      inner = parent.inner_runs.sole

      patch easy_flow.run_path(inner), params: { asked: "ask", answers: { ask: "yes" } }
      follow_redirect!

      assert_redirected_to easy_flow.run_path(parent)
    end

    test "a visitor taken back to the parent run sees its next step before the parent's job has run" do
      parent = Run.start(parent_flow).tap(&:advance)
      inner = parent.inner_runs.sole

      patch easy_flow.run_path(inner), params: { asked: "ask", answers: { ask: "yes" } }
      2.times { follow_redirect! }

      assert_select "legend", text: /Anything else\?/
    end

    test "a visitor who opens the parent run while its inner run is unfinished is taken to the inner run" do
      parent = Run.start(parent_flow).tap(&:advance)

      get easy_flow.run_path(parent)

      assert_redirected_to easy_flow.run_path(parent.inner_runs.sole)
    end

    test "a parent flow that loops back to an earlier question after an inner run ends asks that question again" do
      looping = published("looping",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "pick", "type" => "question", "text" => "Which quiz?", "options" => [ "inner" ] },
                 { "id" => "quiz", "type" => "flow_step", "flow" => inner_flow.id.to_s, "version" => 1 } ],
        edges: [ { "from" => "start", "to" => "pick" }, { "from" => "pick", "to" => "quiz" }, { "from" => "quiz", "to" => "pick", "on" => "bought" } ])
      parent = Run.start(looping)
      patch easy_flow.run_path(parent), params: { asked: "pick", answers: { pick: "inner" } }
      get easy_flow.run_path(parent)

      patch easy_flow.run_path(parent.inner_runs.sole), params: { asked: "ask", answers: { ask: "yes" } }
      2.times { follow_redirect! }

      assert_select "legend", text: /Which quiz\?/
    end

    test "a host that names its runs' addresses takes a visitor into an inner run at its own address" do
      parent = Run.start(parent_flow)

      get "/coded/runs/run-#{parent.id}"

      assert_redirected_to "/coded/runs/run-#{parent.inner_runs.sole.id}"
    end
  end
end
