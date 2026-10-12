require "test_helper"

class RunAddressTest < ActionDispatch::IntegrationTest
  def flow
    @flow ||= EasyFlow::Definition.create!(host: "dummy", slug: "fee").tap do |flow|
      flow.record_definition(flowing(
        "slug" => "fee", "entry" => "annual_fee",
        "nodes" => [ { "id" => "annual_fee", "type" => "question", "text" => "Does the card have an annual fee?",
                       "options" => [ { "value" => "yes", "label" => "Yes" }, { "value" => "no", "label" => "No" } ] } ],
        "edges" => []
      ))
      flow.publish
    end
  end

  test "a host that names its runs' addresses sends a visitor who starts a flow to that address" do
    post "/coded/#{flow.slug}/runs"

    assert_redirected_to "/coded/runs/run-#{EasyFlow::Run.sole.id}"
  end
end
