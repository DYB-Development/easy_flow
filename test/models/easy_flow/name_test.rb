require "test_helper"

module EasyFlow
  class NameTest < ActiveSupport::TestCase
    def registry
      Registry.new.tap do |built|
        built.register(StepType.define(:told) { step_name "Told"; setting :text, type: :string; names_by :text })
      end
    end

    test "shows a step by the name it was given" do
      assert_equal "Ask first", Name.shown(Node.new(id: "first", type: "told", config: { "text" => "Ask first" }), registry)
    end

    test "shows a step with no name of its own by its type's name" do
      assert_equal "Told", Name.shown(Node.new(id: "first", type: "told", config: {}), registry)
    end

    test "shows a step of an unknown type without its id" do
      assert_equal "Unnamed step", Name.shown(Node.new(id: "first", type: "gone", config: {}), registry)
    end

    test "shows a step that is not in the flow as a step" do
      assert_equal "a step", Name.shown(nil, registry)
    end
  end
end
