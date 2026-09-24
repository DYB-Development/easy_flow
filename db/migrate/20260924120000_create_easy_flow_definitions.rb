class CreateEasyFlowDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :easy_flow_definitions do |t|
      t.string :slug
      t.string :title
      t.string :start_label
      t.string :kind
      t.string :status, null: false, default: "active"
      t.string :persists, null: false, default: "unsaved"
      t.json :document
      t.integer :definition_cursor
      t.json :changes_since_version
      t.json :undo_history
      t.json :undone_changes
      t.timestamps
    end

    add_index :easy_flow_definitions, :slug, unique: true
  end
end
