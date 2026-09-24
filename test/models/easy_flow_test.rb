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

    test "refuses a check it does not ship" do
      assert_raises(UnknownCheck) { EasyFlow.check(:invented) }
    end
  end
end
