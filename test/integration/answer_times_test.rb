require "test_helper"

module EasyFlow
  class AnswerTimesTest < ActionDispatch::IntegrationTest
    def evening
      @evening ||= Definition.create!(host: "dummy", slug: "evening").tap do |flow|
        flow.record_definition(flowing("slug" => "evening", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "question" => "Ready?", "options" => [ "yes" ] },
                       { "id" => "late", "type" => "compare", "step" => "a", "output" => "answered_hour", "comparison" => "at least", "amount" => 17 },
                       { "id" => "night", "type" => "question", "question" => "Evening plans?", "options" => [ "out" ] },
                       { "id" => "day", "type" => "question", "question" => "Day plans?", "options" => [ "work" ] } ],
          "edges" => [ { "from" => "a", "to" => "late" }, { "from" => "late", "to" => "night", "on" => "true" }, { "from" => "late", "to" => "day", "on" => "false" } ]))
        flow.publish
      end
    end

    def holding
      @holding ||= Definition.create!(host: "dummy", slug: "holding").tap do |flow|
        flow.record_definition(flowing("slug" => "holding", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "question" => "Ready?", "options" => [ "yes" ] },
                       { "id" => "hold", "type" => "wait", "step" => "a", "minutes" => 30 },
                       { "id" => "b", "type" => "question", "question" => "Still there?", "options" => [ "yes" ] } ],
          "edges" => [ { "from" => "a", "to" => "hold" }, { "from" => "hold", "to" => "b" } ]))
        flow.publish
      end
    end

    test "a stored run asks the step the time of its earlier answer leads to" do
      run = Run.start(evening)
      travel_to(Time.zone.local(2026, 10, 12, 18, 0)) { run.record("a", "yes") }

      get easy_flow.run_path(run)

      assert_select "legend", text: "Evening plans?"
    end

    test "a finished run lists the answers along the route the times of its answers took" do
      run = Run.start(evening)
      travel_to(Time.zone.local(2026, 10, 12, 18, 0)) { run.record("a", "yes") }
      run.record("night", "out")

      get easy_flow.run_path(run)

      assert_select "li[data-answer=night]"
    end

    test "a flow keeping nothing lets a visitor checking again past a Wait step once its time has come" do
      travel_to(Time.zone.local(2026, 10, 12, 9, 0)) { get easy_flow.flow_step_path(holding.slug), params: { answers: { a: "yes" }, asked: "a" } }
      check_again = css_select("a").find { |link| link.text.strip == "Check again" }&.[]("href")

      travel_to(Time.zone.local(2026, 10, 12, 9, 31)) { get check_again.to_s }

      assert_select "legend", text: "Still there?"
    end
  end
end
