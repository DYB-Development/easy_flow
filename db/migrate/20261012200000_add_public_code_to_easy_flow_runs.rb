class AddPublicCodeToEasyFlowRuns < ActiveRecord::Migration[8.1]
  class Run < ActiveRecord::Base
    self.table_name = "easy_flow_runs"
  end

  def up
    add_column :easy_flow_runs, :public_code, :string
    Run.reset_column_information
    Run.find_each { |run| run.update_columns(public_code: PublicCode.generate) }
    change_column_null :easy_flow_runs, :public_code, false
    add_index :easy_flow_runs, :public_code, unique: true
  end

  def down
    remove_column :easy_flow_runs, :public_code
  end
end
