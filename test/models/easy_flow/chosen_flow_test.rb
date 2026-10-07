require "test_helper"

module EasyFlow
  class ChosenFlowTest < ActiveSupport::TestCase
    test "reads the version a step names by its flow setting and version number" do
      onboarding = Definition.create!(host: "dummy", slug: "onboarding")
      second = onboarding.definition_versions.create!(number: 2, definition: { "slug" => "onboarding" })
      node = Node.new(id: "inner", type: "flow_step", config: { "flow" => onboarding.id.to_s, "version" => 2 })

      assert_equal second, ChosenFlow.of(node).version
    end
  end
end
