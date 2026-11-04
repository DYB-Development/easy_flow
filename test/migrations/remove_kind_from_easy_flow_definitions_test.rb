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
  end
end
