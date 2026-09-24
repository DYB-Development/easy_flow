require "test_helper"

module EasyFlow
  class EasyFlowTest < ActiveSupport::TestCase
    test "draws a step with the template it ships when nothing replaces it" do
      assert_equal "easy_flow/steps/choosing", EasyFlow.drawing
    end

    test "draws every step with the template a host puts in its place" do
      EasyFlow.draws_with("host/steps/panel")

      assert_equal "host/steps/panel", EasyFlow.drawing
    ensure
      EasyFlow.draws_with(nil)
    end

    test "renders the visitor pages in its own layout when the host names none" do
      assert_equal "easy_flow/application", EasyFlow.layout
    end

    test "builds its controllers on a plain controller when the host names none" do
      assert_equal "ActionController::Base", EasyFlow.base_controller
    end

    test "refuses a check it does not ship" do
      assert_raises(UnknownCheck) { EasyFlow.check(:invented) }
    end
  end
end
