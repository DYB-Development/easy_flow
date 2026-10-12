require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261012200000_add_public_code_to_easy_flow_runs").to_s

module EasyFlow
  class AddPublicCodeToEasyFlowRunsTest < ActiveSupport::TestCase
    def published_flow
      Definition.create!(host: "dummy", slug: "coded").tap do |flow|
        flow.definition_versions.create!(number: 1, definition: flowing({ "slug" => "coded", "entry" => "a", "nodes" => [ { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] } ] }))
        flow.publish_version(flow.definition_versions.first)
      end
    end

    def migrate(direction)
      ActiveRecord::Migration.suppress_messages { AddPublicCodeToEasyFlowRuns.new.public_send(direction) }
      Run.reset_column_information
    end

    teardown do
      migrate(:up) unless Run.column_names.include?("public_code")
    end

    test "every run started before the release is given its own code" do
      flow = published_flow
      migrate(:down)
      runs = 2.times.map { Run.start(flow) }

      migrate(:up)

      assert_equal 2, runs.map { |run| run.reload.public_code }.grep(/\A[a-zA-Z0-9]{24}\z/).uniq.size
    end
  end
end
