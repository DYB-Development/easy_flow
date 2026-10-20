require "test_helper"

module EasyFlow
  class MultipleSelectStepTest < ActionDispatch::IntegrationTest
    def selecting
      @selecting ||= Definition.create!(host: "dummy", slug: "selecting").tap do |flow|
        flow.record_definition(flowing("slug" => "selecting", "entry" => "primes",
          "nodes" => [ { "id" => "primes", "type" => "multiple_select", "question" => "Which are prime?",
                         "answers" => [ { "value" => "two", "label" => "2", "weight" => 1 }, { "value" => "four", "label" => "4" },
                                        { "value" => "five", "label" => "5", "weight" => 1 } ] } ]))
        flow.publish
      end
    end

    test "a visitor is offered a box to tick for each answer" do
      get easy_flow.run_path(Run.start(selecting))

      assert_equal [ "two", "four", "five" ], css_select("input[type=checkbox][name='answers[primes][]']").map { |box| box["value"] }
    end

    test "the run keeps every value the visitor picked" do
      run = Run.start(selecting)

      patch easy_flow.run_path(run), params: { asked: "primes", answers: { primes: [ "", "two", "five" ] } }

      assert_equal [ "two", "five" ], run.reload.recorded[:primes]
    end
  end
end
