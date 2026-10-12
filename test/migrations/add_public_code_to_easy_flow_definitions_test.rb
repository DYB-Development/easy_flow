require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261012210000_add_public_code_to_easy_flow_definitions").to_s
require EasyFlow::Engine.root.join("db/migrate/20261012210100_add_public_code_to_easy_flow_versions").to_s

module EasyFlow
  class AddPublicCodeToEasyFlowDefinitionsTest < ActiveSupport::TestCase
    def migrate(direction)
      ActiveRecord::Migration.suppress_messages do
        AddPublicCodeToEasyFlowDefinitions.new.public_send(direction)
        AddPublicCodeToEasyFlowVersions.new.public_send(direction)
      end
      Definition.reset_column_information
      Version.reset_column_information
    end

    teardown do
      migrate(:up) unless Definition.column_names.include?("public_code")
    end

    test "every flow and flow version made before the release is given its own code" do
      migrate(:down)
      flows = 2.times.map { |time| Definition.create!(host: "dummy", slug: "old-#{time}") }
      versions = flows.map { |made| made.definition_versions.create!(number: 1, definition: flowing({ "slug" => made.slug, "entry" => "a", "nodes" => [ { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] } ] })) }

      migrate(:up)

      assert_equal 4, (flows + versions).map { |record| record.reload.public_code }.grep(/\A[a-zA-Z0-9]{24}\z/).uniq.size
    end
  end
end
