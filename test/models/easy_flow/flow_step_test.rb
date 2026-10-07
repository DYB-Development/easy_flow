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

    test "holds a run that reaches it until its value is recorded" do
      parent = Document.new({ "entry" => "start",
        "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "inner", "type" => "flow_step" }, { "id" => "done", "type" => "terminal" } ],
        "edges" => [ { "from" => "start", "to" => "inner" }, { "from" => "inner", "to" => "done" } ] })

      assert_equal "inner", Digest.new(parent).next_step({}).id
    end

    test "starts another flow" do
      assert_predicate FlowStep.step_type, :starts_a_flow?
    end

    test "is named after the flow and version it runs" do
      onboarding = Definition.create!(host: "dummy", slug: "onboarding", title: "Onboarding")
      node = Node.new(id: "inner", type: "flow_step", config: { "flow" => onboarding.id.to_s, "version" => 2 })

      assert_equal "Onboarding, version 2", FlowStep.step_type.name_of(node)
    end
  end
end
