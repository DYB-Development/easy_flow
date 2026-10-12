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

  test "a host that names its runs' addresses opens a run at that address" do
    run = EasyFlow::Run.start(flow)

    get "/coded/runs/run-#{run.id}"

    assert_select "form[action=?]", "/coded/runs/run-#{run.id}"
  end

  test "a host finding runs by its own address still only finds runs of its own flows" do
    console = EasyFlow::Definition.create!(host: "console", slug: "fee").tap do |other|
      other.record_definition(flowing("slug" => "fee", "entry" => "annual_fee", "nodes" => [ { "id" => "annual_fee", "type" => "question", "text" => "Fee?", "options" => [ { "value" => "yes", "label" => "Yes" } ] } ], "edges" => []))
      other.publish
    end
    run = EasyFlow::Run.start(console)

    get "/coded/runs/run-#{run.id}"

    assert_response :not_found
  end
end
