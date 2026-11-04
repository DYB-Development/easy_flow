class RemoveKindFromEasyFlowDefinitions < ActiveRecord::Migration[8.1]
  def up
    remove_column :easy_flow_definitions, :kind
  end
end
