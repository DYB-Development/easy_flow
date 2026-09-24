require "test_helper"

module EasyFlow
  class HostVisitorTest < ActionDispatch::IntegrationTest
    def published
      @published ||= Definition.create!(host: "dummy", slug: "fee-check").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "fee-check", "entry" => "annual_fee",
          "nodes" => [ { "id" => "annual_fee", "type" => "question", "text" => "Does the card have an annual fee?",
                         "options" => [ { "value" => "yes", "label" => "Yes" } ] } ],
          "edges" => []
        ))
        flow.publish
      end
    end

    test "a visitor on one host's path does not reach another host's flow" do
      get console_flows.flow_path(published.slug)

      assert_response :not_found
    end
  end
end
