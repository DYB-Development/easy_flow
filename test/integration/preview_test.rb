require "test_helper"

module EasyFlow
  class PreviewTest < ActionDispatch::IntegrationTest
    def unpublished
      @unpublished ||= Definition.create!(host: "dummy", slug: "unpublished").tap do |flow|
        flow.edit_history.edit_document(flowing(
          "slug" => "unpublished", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "question" => "Budget?",
                         "answers" => [ { "value" => "high", "label" => "Generous" } ] },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "budget", "to" => "end" } ]
        ))
      end
    end

    test "trying a flow that has never been published asks its first question" do
      get easy_flow.step_manage_flow_preview_path(unpublished)

      assert_select "form", /Budget\?/
    end

    test "reaching the end of a flow being tried offers a way to start over" do
      get easy_flow.step_manage_flow_preview_path(unpublished), params: { answers: { budget: "high" } }

      assert_response :success
      assert_select "a[href=?]", easy_flow.manage_flow_preview_path(unpublished)
    end
  end
end
