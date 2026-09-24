require "test_helper"

module EasyFlow
  class StepProcessTest < ActionDispatch::IntegrationTest
    def delivering(persists: :each_step, slug: "delivering")
      Definition.create!(host: "dummy", slug: slug, persists: persists).tap do |flow|
        flow.record_definition(flowing({ "slug" => slug, "entry" => "who",
          "nodes" => [ { "id" => "who", "type" => "question", "question" => "Who?",
                         "answers" => [ { "value" => "sam" } ] },
                       { "id" => "send", "type" => "deliver", "message" => "Thanks", "to" => "who" },
                       { "id" => "after", "type" => "question", "question" => "And then?",
                         "answers" => [ { "value" => "ok" } ] } ],
          "edges" => [ { "from" => "who", "to" => "send" },
                       { "from" => "send", "to" => "after" } ] }))
        flow.publish
      end
    end

    test "records what a step's process made of the answers before it" do
      run = Run.start(delivering)
      run.record(:who, "sam")

      get easy_flow.run_path(run)

      assert_equal true, run.reload.recorded[:send]
    end

    test "walks past a step that acts to the next step that asks" do
      run = Run.start(delivering)
      run.record(:who, "sam")

      get easy_flow.run_path(run)

      assert_select "legend", text: /And then\?/
    end

    test "carries a process result forward so a flow keeping nothing does not run it twice" do
      loose = delivering(persists: :unsaved, slug: "loosely")

      get easy_flow.flow_step_path(loose.slug), params: { answers: { who: "sam" } }

      assert_select "input[name=?][value=?]", "answers[send]", "true"
    end
  end
end
