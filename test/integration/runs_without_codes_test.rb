require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261012200000_add_public_code_to_easy_flow_runs").to_s

class RunsWithoutCodesTest < ActionDispatch::IntegrationTest
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

  def migrate(direction)
    ActiveRecord::Migration.suppress_messages { AddPublicCodeToEasyFlowRuns.new.public_send(direction) }
    EasyFlow::Run.reset_column_information
  end

  setup { migrate(:down) }
  teardown { migrate(:up) }

  test "a run in an app that has not run the release's migration is opened at its id and answered there" do
    run = EasyFlow::Run.start(flow)

    get "/host/runs/#{run.id}"

    assert_select "form[action=?]", "/host/runs/#{run.id}"
  end
end
