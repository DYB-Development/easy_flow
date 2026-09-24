require "test_helper"

module EasyFlow
  class StepTemplatesTest < ActionDispatch::IntegrationTest
    def notifying
      @notifying ||= Definition.create!(slug: "notifying").tap do |flow|
        flow.record_definition(flowing({ "slug" => "notifying", "entry" => "tell",
          "nodes" => [ { "id" => "tell", "type" => "notify", "message" => "We will be in touch" } ] }))
        flow.publish
      end
    end

    def asking
      @asking ||= Definition.create!(slug: "asking").tap do |flow|
        flow.record_definition(flowing({ "slug" => "asking", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "question" => "Budget?",
                         "answers" => [ { "value" => "low" } ] } ] }))
        flow.publish
      end
    end

    test "draws every step with the template a host puts in place of the shipped one" do
      EasyFlow.draws_with("steps/everything")

      get easy_flow.flow_step_path(asking.slug)

      assert_select "[data-drawn-by=?]", "everything"
    ensure
      EasyFlow.draws_with(nil)
    end

    test "draws a step with the template its own type names" do
      get easy_flow.flow_step_path(notifying.slug)

      assert_select "[data-drawn-by=?]", "notify"
    end
  end
end
