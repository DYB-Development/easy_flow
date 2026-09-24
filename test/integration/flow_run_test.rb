require "test_helper"

module EasyFlow
  class FlowRunTest < ActionDispatch::IntegrationTest
    def flowed
      @flowed ||= Definition.create!(slug: "flowed").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "flowed", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "What is your budget?", "tag" => "money",
                         "options" => [ { "value" => "low", "label" => "Modest", "weight" => 1 },
                                        { "value" => "high", "label" => "Generous", "weight" => 5 } ] },
                       { "id" => "gate", "type" => "condition", "step" => "budget", "output" => "answer", "comparison" => "is", "answer" => "high" },
                       { "id" => "posh", "type" => "question", "text" => "Which premium tier?",
                         "options" => [ { "value" => "a", "weight" => 3 } ] },
                       { "id" => "plain", "type" => "question", "text" => "Which basic tier?",
                         "options" => [ { "value" => "b", "weight" => 1 } ] } ],
          "edges" => [ { "from" => "budget", "to" => "gate" },
                       { "from" => "gate", "to" => "posh", "on" => true },
                       { "from" => "gate", "to" => "plain", "on" => false } ]
        ))
        flow.publish
      end
    end

    test "a flow keeping a run at the end stores it once the flow finishes" do
      flowed.update!(persists: :on_finish)

      assert_difference -> { Run.count }, 1 do
        get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high", posh: "a" } }
      end
    end

    test "a flow keeping nothing stores no run when it finishes" do
      assert_no_difference -> { Run.count } do
        get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high", posh: "a" } }
      end
    end

    test "a finished flow shows what was said" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_select "[data-answer=?]", "budget"
    end

    test "a visitor can see the intro of a flow" do
      get easy_flow.flow_path(flowed.slug)

      assert_response :success
    end

    test "the intro links into the flow" do
      get easy_flow.flow_path(flowed.slug)

      assert_select "a[href=?]", easy_flow.flow_step_path(flowed.slug)
    end

    test "a visitor is asked the step the flow begins at" do
      get easy_flow.flow_step_path(flowed.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor is offered a labelled choice for each option" do
      get easy_flow.flow_step_path(flowed.slug)

      assert_select "label", text: /Generous/
    end

    test "answering sends the visitor down the branch their answer selects" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high" } }

      assert_select "legend", text: /Which premium tier\?/
    end

    test "the other answer sends them down the other branch" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low" } }

      assert_select "legend", text: /Which basic tier\?/
    end

    test "a visitor reaching the end is told the run is complete" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_response :success
    end

    test "a saved session walks the same flow" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }
      get easy_flow.run_path(run)

      assert_select "legend", text: /Which premium tier\?/
    end

    test "a saved session records the answer against the step that asked it" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }

      assert_equal({ budget: "high" }, run.reload.recorded)
    end

    test "a visitor runs the published version, not what the author is editing" do
      flow = flowed
      flow.publish
      flow.update!(document: { "slug" => flow.slug, "entry" => "gone", "nodes" => [], "edges" => [] })

      get easy_flow.flow_step_path(flow.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor keeps running the published version after a newer one is created" do
      flow = flowed
      flow.publish
      flow.update!(document: { "slug" => flow.slug, "entry" => "later",
        "nodes" => [ { "id" => "later", "type" => "question", "question" => "Something else?" } ], "edges" => [] })
      flow.create_version

      get easy_flow.flow_step_path(flow.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor cannot start on a version that has been retired" do
      flow = flowed
      flow.retire_version(flow.live_version)

      get easy_flow.flow_step_path(flow.slug)

      assert_response :not_found
    end
  end
end
