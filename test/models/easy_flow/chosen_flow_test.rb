require "test_helper"

module EasyFlow
  class ChosenFlowTest < ActiveSupport::TestCase
    test "reads the version a step names by its flow setting and version number" do
      onboarding = Definition.create!(host: "dummy", slug: "onboarding")
      second = onboarding.definition_versions.create!(number: 2, definition: { "slug" => "onboarding" })
      node = Node.new(id: "inner", type: "flow_step", config: { "flow" => onboarding.id.to_s, "version" => 2 })

      assert_equal second, ChosenFlow.of(node).version
    end

    test "follows the rule a step type declares for working out its flow and version" do
      onboarding = Definition.create!(host: "dummy", slug: "onboarding")
      second = onboarding.definition_versions.create!(number: 2, definition: { "slug" => "onboarding" })
      offers = Registry.new.tap { |built| built.register(StepType.define(:offer) { starts_a_flow; chooses_flow { |_node| { flow: onboarding.id, version: 2 } } }) }

      assert_equal second, ChosenFlow.of(Node.new(id: "a", type: "offer", config: {}), registry: offers).version
    end

    test "chooses nothing for a step that chooses from the run when there is no run, without calling its chooser" do
      picks = Registry.new.tap { |built| built.register(StepType.define(:run_pipeline) { starts_a_flow; chooses_flow_from_run { |_node, run| { flow: run.fetch(:flow) } } }) }

      assert_nil ChosenFlow.of(Node.new(id: "a", type: "run_pipeline", config: {}), registry: picks).flow_id
    end
  end
end
