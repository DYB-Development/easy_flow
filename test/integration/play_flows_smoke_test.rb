require "test_helper"

module EasyFlow
  class PlayFlowsSmokeTest < ActionDispatch::IntegrationTest
    def published(slug, nodes:, edges:, title: nil)
      Definition.create!(host: "dummy", slug: slug, title: title, persists: :each_step).tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def quiz(slug, question)
      published(slug, title: slug.titleize,
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "ask", "type" => "question", "text" => question, "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "ask" }, { "from" => "ask", "to" => "done" } ])
    end

    def quizzes
      @quizzes ||= [ quiz("history", "History quiz?"), quiz("science", "Science quiz?") ]
    end

    def event
      published("event",
        nodes: [ { "id" => "start", "type" => "start" }, { "id" => "play", "type" => "play_flows", "flows" => quizzes.map { |each| each.id.to_s } },
                 { "id" => "after", "type" => "question", "text" => "Play again?", "options" => [ "no" ] }, { "id" => "done", "type" => "terminal" } ],
        edges: [ { "from" => "start", "to" => "play" }, { "from" => "play", "to" => "after" }, { "from" => "after", "to" => "done" } ])
    end

    def answer(step, value)
      patch path, params: { asked: step, answers: { step => value } }
      follow_redirect! while response.redirect?
    end

    test "a visitor plays each listed flow in the order they pick and the parent run moves on after the last" do
      post easy_flow.flow_runs_path(event.slug)
      follow_redirect! while response.redirect?

      answer("play", quizzes.last.id.to_s)
      answer("ask", "yes")
      answer("play@2", quizzes.first.id.to_s)
      answer("ask", "yes")

      assert_select "legend", text: "Play again?"
    end
  end
end
