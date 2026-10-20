require "test_helper"

module EasyFlow
  class FillInTheBlankStepTest < ActionDispatch::IntegrationTest
    def typing
      @typing ||= Definition.create!(host: "dummy", slug: "typing").tap do |flow|
        flow.record_definition(flowing("slug" => "typing", "entry" => "capital",
          "nodes" => [ { "id" => "capital", "type" => "fill_in_the_blank", "question" => "What is the capital of France?",
                         "accepted_answers" => [ { "value" => "Paris" }, { "value" => "Paree" } ] } ]))
        flow.publish
      end
    end

    test "a visitor is offered a box to type an answer in" do
      get easy_flow.run_path(Run.start(typing))

      assert_select "input[type=text][name='answers[capital]']"
    end
  end
end
