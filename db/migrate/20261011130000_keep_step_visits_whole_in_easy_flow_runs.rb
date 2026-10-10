class KeepStepVisitsWholeInEasyFlowRuns < ActiveRecord::Migration[8.1]
  class Run < ActiveRecord::Base
    self.table_name = "easy_flow_runs"
  end

  def up
    Run.find_each do |run|
      run.update_columns(recorded: run.recorded.to_h.transform_values { |value| whole?(value) ? value : { "value" => value } })
    end
  end

  def down
    Run.find_each do |run|
      run.update_columns(recorded: run.recorded.to_h.transform_values { |value| whole?(value) ? value["value"] : value })
    end
  end

  private

  def whole?(value)
    value.is_a?(Hash) && value.key?("value") && (value.keys - %w[value completed_at]).empty?
  end
end
