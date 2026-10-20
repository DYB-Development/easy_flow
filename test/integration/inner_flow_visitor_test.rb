require "test_helper"

module EasyFlow
  class InnerFlowVisitorTest < ActionDispatch::IntegrationTest
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
  end
end
