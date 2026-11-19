require "test_helper"

module EasyFlow
  class ForEachSmokeTest < ActionDispatch::IntegrationTest
    def unsaved_flow
      nodes = [ { "id" => "start", "type" => "start" },
                { "id" => "pick", "type" => "question", "question" => "Which?", "answers" => [ { "value" => "good" } ] },
                { "id" => "variants", "type" => "for_each", "list" => "pick.answer", "holds" => [ "write" ] },
                { "id" => "write", "type" => "question", "question" => "Write it", "answers" => [ { "value" => "done" } ] },
                { "id" => "done", "type" => "terminal" } ]
      edges = [ { "from" => "start", "to" => "pick" }, { "from" => "pick", "to" => "variants" },
                { "from" => "variants", "to" => "write" }, { "from" => "write", "to" => "done" } ]

      Definition.create!(host: "dummy", slug: "unsaved-each", persists: :unsaved).tap do |built|
        built.publish_version(built.definition_versions.create!(number: 1, definition: { "slug" => "unsaved-each", "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    test "a flow that saves no run tells the visitor a for_each step needs a flow that saves its runs" do
      get easy_flow.flow_step_path(unsaved_flow.slug), params: { asked: "pick", answers: { pick: "good" } }

      assert_includes response.body, "Steps can only be run for each item in a flow that saves its runs."
    end
  end
end
