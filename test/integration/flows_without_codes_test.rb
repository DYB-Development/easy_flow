require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261012210000_add_public_code_to_easy_flow_definitions").to_s
require EasyFlow::Engine.root.join("db/migrate/20261012210100_add_public_code_to_easy_flow_versions").to_s

module EasyFlow
  class FlowsWithoutCodesTest < ActionDispatch::IntegrationTest
    def migrate(direction)
      ActiveRecord::Migration.suppress_messages do
        AddPublicCodeToEasyFlowDefinitions.new.public_send(direction)
        AddPublicCodeToEasyFlowVersions.new.public_send(direction)
      end
      Definition.reset_column_information
      Version.reset_column_information
    end

    setup { migrate(:down) }
    teardown { migrate(:up) }

    test "a flow in an app that has not run the release's migrations is managed at its id" do
      flow = Definition.create!(host: "dummy", slug: "old", title: "Old")

      get "/easy_flow/manage/flows/#{flow.id}"

      assert_select "a[href=?]", "/easy_flow/manage/flows/#{flow.id}/preview"
    end
  end
end
