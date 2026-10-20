require "test_helper"

module EasyFlow
  class InnerFlowSmokeTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    def published(slug, nodes:, edges:)
      Definition.create!(host: "dummy", slug: slug, persists: :each_step).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def quiz(slug, question)
      published(slug,
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "ask", "type" => "question", "text" => question, "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal", "output" => "finished" } ],
        edges: [ { "from" => "start", "to" => "ask" }, { "from" => "ask", "to" => "done" } ])
    end

    def quiz_branch(name, flow)
      [ [ { "id" => "#{name}_taken", "type" => "condition", "step" => name, "output" => "result", "comparison" => "is", "answer" => "finished" },
          { "id" => name, "type" => "flow_step", "flow" => flow.id.to_s, "version" => 1 },
          { "id" => "#{name}_all", "type" => "all_or_any", "join" => "all of",
            "comparisons" => %w[first second].map { |each| { "step" => each, "output" => "completed_minute", "comparison" => "at least" } } } ],
        [ { "from" => "route", "to" => "#{name}_taken", "on" => name },
          { "from" => "#{name}_taken", "to" => "pick", "on" => "true" }, { "from" => "#{name}_taken", "to" => name, "on" => "false" },
          { "from" => name, "to" => "#{name}_all", "on" => "finished" },
          { "from" => "#{name}_all", "to" => "done", "on" => "true" }, { "from" => "#{name}_all", "to" => "pick", "on" => "false" } ] ]
    end

    def event
      first_nodes, first_edges = quiz_branch("first", quiz("first-quiz", "First quiz?"))
      second_nodes, second_edges = quiz_branch("second", quiz("second-quiz", "Second quiz?"))
      published("event",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "pick", "type" => "question", "text" => "Which quiz next?", "options" => %w[first second] },
                 { "id" => "route", "type" => "switch", "step" => "pick" }, { "id" => "done", "type" => "terminal" } ] + first_nodes + second_nodes,
        edges: [ { "from" => "start", "to" => "pick" }, { "from" => "pick", "to" => "route" } ] + first_edges + second_edges)
    end

    def answer(step, value)
      patch path, params: { asked: step, answers: { step => value } }
      follow_redirect! while response.redirect?
    end

    test "a visitor plays each inner flow of a parent run in turn and the parent run ends after the last" do
      post easy_flow.flow_runs_path(event.slug)
      follow_redirect!

      answer("pick", "first")
      answer("ask", "yes")
      answer("pick@2", "second")
      answer("ask", "yes")

      assert_select "[data-answer=?]", "second"
    end

    test "a visitor who finishes an inner flow whose End step has no output moves on in the parent run" do
      quiet = published("quiet-quiz",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "ask", "type" => "question", "text" => "Ready?", "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "ask" }, { "from" => "ask", "to" => "done" } ])
      parent = published("scored",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "quiz", "type" => "flow_step", "flow" => quiet.id.to_s, "version" => 1 },
                 { "id" => "after", "type" => "question", "text" => "Play again?", "options" => [ "no" ] }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "quiz" }, { "from" => "quiz", "to" => "after", "on" => "ended" }, { "from" => "after", "to" => "done" } ])
      post easy_flow.flow_runs_path(parent.slug)
      follow_redirect! while response.redirect?

      answer("ask", "yes")
      answer("after", "no")

      assert_select "[data-answer=?]", "after"
    end
  end
end
