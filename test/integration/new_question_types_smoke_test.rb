require "test_helper"

module EasyFlow
  class NewQuestionTypesSmokeTest < ActionDispatch::IntegrationTest
    test "an admin builds a flow of a multiple select and a fill in the blank question and a visitor's run keeps both answers" do
      flow = Definition.create!(host: "dummy", slug: "quiz")
      flow.record_definition(flowing("slug" => "quiz", "entry" => "end", "nodes" => [ { "id" => "end", "type" => "terminal" } ]))
      canvas = easy_flow.manage_flow_canvas_path(flow)
      post "#{canvas}/steps", params: { id: "primes", type: "multiple_select", from: "start", to: "end" }
      patch "#{canvas}/steps/primes", params: { config: { question: "Which are prime?", category: "maths", required: true,
        answers: [ { value: "two", label: "2", weight: 1 }, { value: "four", label: "4", weight: 0 } ] } }
      post "#{canvas}/steps", params: { id: "capital", type: "fill_in_the_blank", from: "primes", to: "end" }
      patch "#{canvas}/steps/capital", params: { config: { question: "Capital of France?", category: "places", accepted_answers: [ { value: "Paris" } ] } }
      post "#{canvas}/versions"
      post "#{canvas}/publish"
      run = Run.start(flow.reload)

      patch easy_flow.run_path(run), params: { asked: "primes", answers: { primes: [ "", "two", "four" ] } }
      patch easy_flow.run_path(run), params: { asked: "capital", answers: { capital: "Paris" } }

      assert_equal({ primes: [ "two", "four" ], capital: "Paris" }, run.reload.recorded.slice(:primes, :capital))
    end
  end
end
