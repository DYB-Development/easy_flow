require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261104184315_remove_kind_from_easy_flow_definitions").to_s

module EasyFlow
  class RemoveKindFromEasyFlowDefinitionsTest < ActiveSupport::TestCase
    def connection
      Definition.connection
    end

    def stored_field?
      connection.schema_cache.clear!
      connection.column_exists?(:easy_flow_definitions, :kind)
    end

    def migrate(direction)
      ActiveRecord::Migration.suppress_messages { RemoveKindFromEasyFlowDefinitions.new.public_send(direction) }
    end

    def restore_stored_field
      connection.add_column(:easy_flow_definitions, :kind, :string) unless stored_field?
      Definition.reset_column_information
    end

    teardown do
      connection.remove_column(:easy_flow_definitions, :kind) if stored_field?
      Definition.reset_column_information
    end

    test "it removes the stored field" do
      restore_stored_field

      migrate(:up)

      assert_not stored_field?
    end

    test "it does nothing when the stored field is already gone" do
      connection.remove_column(:easy_flow_definitions, :kind) if stored_field?

      assert_nothing_raised { migrate(:up) }
    end

    test "rolling it back restores a nullable text column" do
      migrate(:down)

      assert connection.columns(:easy_flow_definitions).find { |column| column.name == "kind" }&.then { |column| column.type == :string && column.null }
    end

    test "rolling it back does nothing when the column is already there" do
      restore_stored_field

      assert_nothing_raised { migrate(:down) }
    end

    test "a flow that had a value set and its run keep working once the field is removed" do
      restore_stored_field
      flow = Definition.create!(host: "dummy", slug: "scored-before", persists: :each_step)
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: flowing("slug" => "scored-before", "entry" => "ask",
        "nodes" => [ { "id" => "ask", "type" => "question", "text" => "Ready?", "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal" } ],
        "edges" => [ { "from" => "ask", "to" => "done" } ])))
      run = flow.runs.create!(definition_version: flow.live_version)
      connection.execute("UPDATE easy_flow_definitions SET kind = 'scored' WHERE id = #{flow.id}")

      migrate(:up)
      Definition.reset_column_information
      run = Run.find(run.id)
      run.record(:ask, "yes")

      assert_equal "yes", run.reload.recorded[:ask]
    end

    test "a process that loaded the table before the field was removed can still create a flow" do
      restore_stored_field
      Definition.columns
      connection.execute("ALTER TABLE easy_flow_definitions DROP COLUMN kind")

      assert Definition.create!(host: "dummy", slug: "after-the-drop").persisted?
    end
  end
end
