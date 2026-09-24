class CreateEasyFlowRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :easy_flow_runs do |t|
      t.references :flow, null: false, foreign_key: { to_table: :easy_flow_definitions }
      t.references :definition_version, null: false, foreign_key: { to_table: :easy_flow_versions }
      t.references :owner, polymorphic: true
      t.json :recorded
      t.string :label
      t.string :status
      t.timestamps
    end
  end
end
