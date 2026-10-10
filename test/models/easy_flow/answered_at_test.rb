require "test_helper"

module EasyFlow
  class AnsweredAtTest < ActiveSupport::TestCase
    test "reads the hour an answer was given in the app's time zone" do
      hour = Time.use_zone("Pacific Time (US & Canada)") { AnsweredAt.read("answered_hour", Time.utc(2026, 10, 12, 14, 30)) }

      assert_equal 7, hour
    end

    test "reads the weekday an answer was given as 1 for Monday through 7 for Sunday in the app's time zone" do
      weekday = Time.use_zone("Pacific Time (US & Canada)") { AnsweredAt.read("answered_weekday", Time.utc(2026, 10, 12, 3, 0)) }

      assert_equal 7, weekday
    end

    test "reads the whole minutes since 1 January 1970 an answer was given at" do
      assert_equal 29_334_780, AnsweredAt.read("answered_minute", Time.utc(2025, 10, 10, 9, 0, 59))
    end
  end
end
