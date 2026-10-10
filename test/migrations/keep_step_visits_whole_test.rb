require "test_helper"
require EasyFlow::Engine.root.join("db/migrate/20261011130000_keep_step_visits_whole_in_easy_flow_runs").to_s

module EasyFlow
  class KeepStepVisitsWholeTest < ActiveSupport::TestCase
    def stored_run(recorded)
      flow = Definition.create!(host: "dummy", slug: "kept")
      flow.definition_versions.create!(number: 1, definition: flowing({ "slug" => "kept", "entry" => "a", "nodes" => [ { "id" => "a", "type" => "question", "text" => "A", "options" => [ "x" ] } ] }))
      flow.publish_version(flow.definition_versions.first)
      Run.start(flow).tap { |run| run.update_columns(recorded: recorded) }
    end

    def migrate(direction)
      ActiveRecord::Migration.suppress_messages { KeepStepVisitsWholeInEasyFlowRuns.new.public_send(direction) }
    end

    test "wraps each value a run stored before the change in an entry of its own" do
      run = stored_run({ "a" => "x", "b" => { "result" => "passed", "coverage" => 91 } })

      migrate(:up)

      assert_equal({ "a" => { "value" => "x" }, "b" => { "value" => { "result" => "passed", "coverage" => 91 } } }, run.reload.read_attribute(:recorded))
    end
  end
end
