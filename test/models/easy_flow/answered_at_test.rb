require "test_helper"

module EasyFlow
  class AnsweredAtTest < ActiveSupport::TestCase
    test "reads the hour an answer was given in the app's time zone" do
      hour = Time.use_zone("Pacific Time (US & Canada)") { AnsweredAt.read("answered_hour", Time.utc(2026, 10, 12, 14, 30)) }

      assert_equal 7, hour
    end
  end
end
