require "test_helper"

module EasyFlow
  class DrawingTest < ActiveSupport::TestCase
    def registry
      @registry ||= Registry.new.tap do |built|
        built.register(StepType.define(:plain) { awaits_input })
        built.register(StepType.define(:tiled) { drawn_by "flows/steps/tiles" })
      end
    end

    def node(type)
      Node.new(id: "a", type: type, config: {})
    end

    test "falls back to the overall template when a step type names none" do
      assert_equal EasyFlow.drawing, Drawing.of(node("plain"), registry)
    end

    test "prefers the step type's own template to the overall one" do
      EasyFlow.draws_with("host/steps/panel")

      assert_equal "flows/steps/tiles", Drawing.of(node("tiled"), registry)
    ensure
      EasyFlow.draws_with(nil)
    end

    test "draws a step with the template its own type names" do
      assert_equal "flows/steps/tiles", Drawing.of(node("tiled"), registry)
    end
  end
end
