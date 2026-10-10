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

    test "a stored run asks the step the time of its earlier answer leads to" do
      run = Run.start(evening)
      travel_to(Time.zone.local(2026, 10, 12, 18, 0)) { run.record("a", "yes") }

      get easy_flow.run_path(run)

      assert_select "legend", text: "Evening plans?"
    end
  end
end
