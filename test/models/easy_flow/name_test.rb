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
  end
end
