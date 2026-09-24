require "test_helper"

class HostFlowTest < ActionDispatch::IntegrationTest
  def flow
    @flow ||= EasyFlow::Definition.create!(slug: "fee").tap do |flow|
      flow.record_definition(flowing(
        "slug" => "fee", "entry" => "annual_fee",
        "nodes" => [ { "id" => "annual_fee", "type" => "question", "text" => "Does the card have an annual fee?",
                       "options" => [ { "value" => "yes", "label" => "Yes" }, { "value" => "no", "label" => "No" } ] } ],
        "edges" => []
      ))
      flow.publish
    end
  end

  test "a host runs its flows with a runner of its own" do
    get "/host/#{flow.slug}/step"

    assert_select "title", "Chosen by the host"
  end

  test "a host sends a visitor who starts a flow to its own page for the run" do
    post "/host/#{flow.slug}/runs"

    assert_redirected_to "/host/runs/#{EasyFlow::Run.sole.id}"
  end

  test "a host brings a visitor back to its own page for the run after each answer" do
    run = EasyFlow::Run.start(flow)

    patch "/host/runs/#{run.id}", params: { answers: { annual_fee: "yes" } }

    assert_redirected_to "/host/runs/#{run.id}"
  end

  test "a host's page for a run sends each answer back to itself" do
    run = EasyFlow::Run.start(flow)

    get "/host/runs/#{run.id}"

    assert_select "form[action=?]", "/host/runs/#{run.id}"
  end
end
