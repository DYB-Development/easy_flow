require "test_helper"

module EasyFlow
  class AllowedAnswersTest < ActionDispatch::IntegrationTest
    def selling
      @selling ||= Definition.create!(host: "dummy", slug: "selling").tap do |flow|
        flow.record_definition(flowing("slug" => "selling", "entry" => "kind",
          "nodes" => [ { "id" => "kind", "type" => "question", "question" => "What kind?", "options" => [ "pdf", "service" ] },
                       { "id" => "sold_as", "type" => "question", "question" => "How is it sold?", "options" => [ "download", "service", "good" ] },
                       { "id" => "price", "type" => "question", "question" => "What price?", "options" => [ "10", "20" ] } ],
          "edges" => [ { "from" => "kind", "to" => "sold_as" }, { "from" => "sold_as", "to" => "price" } ]))
        flow.publish
      end
    end

    def allowing(&decide)
      EasyFlow.host_named("dummy").allowed_answers = decide
    end

    teardown { EasyFlow.host_named("dummy").allowed_answers = nil }

    test "a step the host says is not asked is passed over" do
      allowing { |step, _answers| [] if step.id == "sold_as" }
      run = Run.start(selling)

      patch easy_flow.run_path(run), params: { answers: { kind: "pdf" } }
      follow_redirect!

      assert_select "legend", text: "What price?"
    end

    test "a step the host allows one answer for records that answer without showing it" do
      allowing { |step, answers| [ "download" ] if step.id == "sold_as" && answers[:kind] == "pdf" }
      run = Run.start(selling)

      patch easy_flow.run_path(run), params: { answers: { kind: "pdf" } }
      get easy_flow.run_path(run)

      assert_equal "download", run.reload.recorded[:sold_as]
    end

    test "a step the host allows several answers for offers only those answers" do
      allowing { |step, _answers| [ "download", "good" ] if step.id == "sold_as" }
      run = Run.start(selling)

      patch easy_flow.run_path(run), params: { answers: { kind: "pdf" } }
      follow_redirect!

      assert_equal [ "download", "good" ], css_select("input[name='answers[sold_as]']").map { |choice| choice["value"] }
    end

    test "a step the host says nothing about offers every answer" do
      allowing { |step, _answers| [ "download" ] if step.id == "price" }
      run = Run.start(selling)

      patch easy_flow.run_path(run), params: { answers: { kind: "pdf" } }
      follow_redirect!

      assert_equal [ "download", "service", "good" ], css_select("input[name='answers[sold_as]']").map { |choice| choice["value"] }
    end
  end
end
