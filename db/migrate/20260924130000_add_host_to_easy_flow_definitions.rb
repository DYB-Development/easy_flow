class AddHostToEasyFlowDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_column :easy_flow_definitions, :host, :string, null: false, default: ""

    remove_index :easy_flow_definitions, :slug, unique: true
    add_index :easy_flow_definitions, [ :host, :slug ], unique: true
  end
end
