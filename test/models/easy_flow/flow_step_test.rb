require "test_helper"

module EasyFlow
  class FlowStepTest < ActiveSupport::TestCase
    test "is registered for a flow to use, named Flow" do
      assert_equal "Flow", EasyFlow.registry.fetch("flow_step").step_name
    end

    test "takes the number of the version it runs" do
      assert_equal :integer, FlowStep.step_type.settings.fields[:version]
    end

    test "takes the flow it runs, chosen from the flows the canvas offers" do
      assert_equal :flow, FlowStep.step_type.settings.fields[:flow]
    end

    test "has one connection out for each different output the chosen version's End steps write" do
      inner = Definition.create!(host: "dummy", slug: "offer")
      inner.publish_version(inner.definition_versions.create!(number: 1, definition: {
        "slug" => "offer", "entry" => "start",
        "nodes" => [ { "id" => "start", "type" => "start" },
                     { "id" => "yes", "type" => "terminal", "output" => "bought" },
                     { "id" => "no", "type" => "terminal", "output" => "declined" },
                     { "id" => "again", "type" => "terminal", "output" => "bought" } ],
        "edges" => [ { "from" => "start", "to" => "yes" } ]
      }))
      parent = Document.new({ "nodes" => [ { "id" => "inner", "type" => "flow_step", "flow" => inner.id.to_s, "version" => 1 } ], "edges" => [] })

      assert_equal %w[bought declined], Digest.new(parent).routing_values("inner")
    end
  end
end
