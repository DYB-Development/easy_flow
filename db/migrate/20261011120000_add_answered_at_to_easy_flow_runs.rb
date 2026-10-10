class AddAnsweredAtToEasyFlowRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :easy_flow_runs, :answered_at, :json
  end
end
