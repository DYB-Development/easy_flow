require "test_helper"

module EasyFlow
  class StartTest < ActiveSupport::TestCase
    test "begins the flow it sits at" do
      assert_predicate Start.step_type, :begins_here?
    end

    test "is registered for a flow to use" do
      assert_equal :start, EasyFlow.registry.fetch("start").id
    end

    test "is named simply as the beginning" do
      assert_equal "Start", Start.step_type.name_of(Node.new(id: "start", type: "start", config: {}))
    end
  end
end
