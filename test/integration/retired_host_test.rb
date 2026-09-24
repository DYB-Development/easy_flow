require "test_helper"

module EasyFlow
  class RetiredHostTest < ActionDispatch::IntegrationTest
    def retired
      @retired ||= Definition.create!(host: "retired", slug: "retired-survey").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "retired-survey", "entry" => "survey",
          "nodes" => [ { "id" => "survey", "type" => "retired_survey", "prompt" => "How was it?" } ],
          "edges" => []
        ))
        flow.publish
      end
    end

    test "the management pages of a host no longer set up are not found" do
      get retired_flows.manage_flows_path

      assert_response :not_found
    end

    test "a flow of a host no longer set up is not found, even one built of step types nobody registers" do
      get easy_flow.flow_step_path(retired.slug)

      assert_response :not_found
    end

    test "a run of a host no longer set up is never opened" do
      run = Run.start(retired)

      get easy_flow.run_path(run)

      assert_response :not_found
    end
  end
end
