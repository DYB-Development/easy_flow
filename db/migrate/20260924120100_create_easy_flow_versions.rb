class CreateEasyFlowVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :easy_flow_versions do |t|
      t.references :flow, null: false, foreign_key: { to_table: :easy_flow_definitions }
      t.integer :number, null: false
      t.json :definition
      t.json :changes_captured
      t.string :status, null: false, default: "draft"
      t.datetime :created_at, null: false
    end

    add_index :easy_flow_versions, [ :flow_id, :number ], unique: true
    add_index :easy_flow_versions, :flow_id, unique: true, where: "status = 'live'",
      name: "index_easy_flow_versions_on_one_live_per_flow"
  end
end
