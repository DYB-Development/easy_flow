class AddPublicCodeToEasyFlowDefinitions < ActiveRecord::Migration[8.1]
  class Record < ActiveRecord::Base
    self.table_name = "easy_flow_definitions"
  end

  def up
    add_column :easy_flow_definitions, :public_code, :string
    Record.reset_column_information
    Record.find_each { |record| record.update_columns(public_code: PublicCode.generate) }
    change_column_null :easy_flow_definitions, :public_code, false
    add_index :easy_flow_definitions, :public_code, unique: true
  end

  def down
    remove_column :easy_flow_definitions, :public_code
  end
end
