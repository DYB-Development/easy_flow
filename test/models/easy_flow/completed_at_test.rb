require "test_helper"

module EasyFlow
  class CompletedAtTest < ActiveSupport::TestCase
    test "reads the hour a step visit completed in the app's time zone" do
      hour = Time.use_zone("Pacific Time (US & Canada)") { CompletedAt.read("completed_hour", Time.utc(2026, 10, 12, 14, 30)) }

      assert_equal 7, hour
    end

    test "reads the weekday a step visit completed on as 1 for Monday through 7 for Sunday in the app's time zone" do
      weekday = Time.use_zone("Pacific Time (US & Canada)") { CompletedAt.read("completed_weekday", Time.utc(2026, 10, 12, 3, 0)) }

      assert_equal 7, weekday
    end

    test "reads the whole minutes since 1 January 1970 a step visit completed at" do
      assert_equal 29_334_780, CompletedAt.read("completed_minute", Time.utc(2025, 10, 10, 9, 0, 59))
    end

    test "gives each step the time its latest visit completed" do
      times = { "a@2" => Time.zone.local(2026, 10, 12, 10, 0), "a" => Time.zone.local(2026, 10, 12, 9, 0), "b" => Time.zone.local(2026, 10, 12, 9, 30) }

      assert_equal({ "a" => Time.zone.local(2026, 10, 12, 10, 0), "b" => Time.zone.local(2026, 10, 12, 9, 30) }, CompletedAt.latest(times))
    end
  end
end
