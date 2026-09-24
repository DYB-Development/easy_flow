require "test_helper"

module EasyFlow
  class SavedSessionsTest < ActionDispatch::IntegrationTest
    def branching
      { "slug" => "saved", "entry" => "budget",
        "nodes" => [ { "id" => "budget", "type" => "question", "text" => "Budget?",
                       "options" => [ { "value" => "low", "label" => "Modest" }, { "value" => "high", "label" => "Generous" } ] },
                     { "id" => "gate", "type" => "condition", "step" => "budget", "output" => "answer", "comparison" => "is", "answer" => "high" },
                     { "id" => "posh", "type" => "question", "text" => "Premium tier?", "options" => [ "gold" ] },
                     { "id" => "plain", "type" => "question", "text" => "Basic tier?", "options" => [ "bronze" ] } ],
        "edges" => [ { "from" => "budget", "to" => "gate" },
                     { "from" => "gate", "to" => "posh", "on" => true },
                     { "from" => "gate", "to" => "plain", "on" => false } ] }
    end

    def saved
      @saved ||= Definition.create!(host: "dummy", slug: "saved", persists: :each_step).tap { |flow| flow.record_definition(flowing(branching)); flow.publish }
    end

    test "starting a saved session sends the visitor to its durable URL" do
      post easy_flow.flow_runs_path(saved.slug)

      assert_redirected_to easy_flow.run_path(Run.last)
    end

    test "a saved session renders the step it is waiting on" do
      run = Run.start(saved)

      get easy_flow.run_path(run)

      assert_select "legend", text: /Budget\?/
    end

    test "answering a step stores the answer against it" do
      run = Run.start(saved)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }

      assert_equal({ budget: "high" }, run.reload.recorded)
    end

    test "a saved session submits its answers back to itself" do
      run = Run.start(saved)

      get easy_flow.run_path(run)

      assert_select "form[action=?]", easy_flow.run_path(run)
    end

    test "an answer sends the visitor down the branch it selects" do
      run = Run.start(saved)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }
      get easy_flow.run_path(run)

      assert_select "legend", text: /Premium tier\?/
    end

    test "going back removes the last answer along the walked path" do
      run = Run.start(saved)
      run.record(:budget, "high")

      patch easy_flow.run_path(run), params: { back: "1" }

      assert_empty run.reload.recorded
    end

    test "returning resumes at the step still waiting" do
      run = Run.start(saved)
      run.record(:budget, "low")

      get easy_flow.run_path(run)

      assert_select "legend", text: /Basic tier\?/
    end

    test "a completed saved session lists what was said" do
      run = Run.start(saved)
      run.record(:budget, "low")
      run.record(:plain, "bronze")

      get easy_flow.run_path(run)

      assert_select "[data-answer=?]", "budget"
    end

    test "a session started before an edit still serves the version it began on" do
      run = Run.start(saved)
      saved.record_definition(flowing(branching).merge(
        "nodes" => branching["nodes"].map { |node| node["id"] == "budget" ? node.merge("text" => "Changed") : node }))

      get easy_flow.run_path(run)

      assert_select "legend", text: /Budget\?/
    end

    test "the intro offers to start a saved session" do
      get easy_flow.flow_path(saved.slug)

      assert_select "form[action=?]", easy_flow.flow_runs_path(saved.slug)
    end

    test "a visitor part way through a withdrawn version is told it was withdrawn" do
      EasyFlow.refusal_method = :note_the_refusal
      run = Run.start(saved)
      run.definition_version.update!(status: :withdrawn)

      get easy_flow.run_path(run)

      assert_equal "EasyFlow::Withdrawn", response.headers["X-Refusal"]
    ensure
      EasyFlow.refusal_method = nil
    end

    test "a withdrawn version keeps the answers already recorded" do
      run = Run.start(saved)
      run.record(:budget, "low")
      run.definition_version.update!(status: :withdrawn)

      get easy_flow.run_path(run)

      assert_equal({ budget: "low" }, run.reload.recorded)
    end

    test "a run carries on after its version is superseded" do
      run = Run.start(saved)
      saved.update!(document: branching.merge("entry" => "gate"))
      saved.publish

      get easy_flow.run_path(run)

      assert_response :success
    end

    test "a run carries on after its version is retired" do
      run = Run.start(saved)
      saved.retire_version(run.definition_version)

      get easy_flow.run_path(run)

      assert_response :success
    end
  end
end
