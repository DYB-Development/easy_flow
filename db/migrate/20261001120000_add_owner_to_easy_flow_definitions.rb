class AddOwnerToEasyFlowDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_reference :easy_flow_definitions, :owner, polymorphic: true, index: false
    remove_index :easy_flow_definitions, [ :host, :slug ], unique: true, name: "index_easy_flow_definitions_on_host_and_slug"
    add_index :easy_flow_definitions, [ :host, :slug ], unique: true, where: "owner_id IS NULL",
      name: "index_easy_flow_definitions_on_host_and_slug"
    add_index :easy_flow_definitions, [ :host, :owner_type, :owner_id, :slug ], unique: true, where: "owner_id IS NOT NULL",
      name: "index_easy_flow_definitions_on_host_owner_and_slug"
  end
end
