require "test_helper"

module EasyFlow
  class WaitTest < ActiveSupport::TestCase
    def wait(config)
      Node.new(id: "hold", type: "wait", config: config)
    end

    test "holds until a number of minutes after the earlier step was answered" do
      node = wait({ "step" => "deploy", "minutes" => 30 })

      assert_equal Time.zone.local(2026, 10, 12, 9, 30), Wait.held_until(node, { "deploy" => Time.zone.local(2026, 10, 12, 9, 0) })
    end

    test "holds until the given time of day the next day when the earlier step was answered after it" do
      node = wait({ "step" => "deploy", "time_of_day" => "09:00" })

      assert_equal Time.zone.local(2026, 10, 13, 9, 0), Wait.held_until(node, { "deploy" => Time.zone.local(2026, 10, 12, 17, 30) })
    end

    test "holds until the given time of day the same day when the earlier step was answered before it" do
      node = wait({ "step" => "deploy", "time_of_day" => "09:00" })

      assert_equal Time.zone.local(2026, 10, 12, 9, 0), Wait.held_until(node, { "deploy" => Time.zone.local(2026, 10, 12, 7, 45) })
    end

    test "holds until the start of a given date in the app's time zone" do
      node = wait({ "step" => "deploy", "date" => "2026-10-20" })

      assert_equal Time.zone.local(2026, 10, 20), Wait.held_until(node, { "deploy" => Time.zone.local(2026, 10, 12, 9, 0) })
    end

    test "holds until the date when a date and a number of minutes are both filled in" do
      node = wait({ "step" => "deploy", "date" => "2026-10-20", "minutes" => 30 })

      assert_equal Time.zone.local(2026, 10, 20), Wait.held_until(node, { "deploy" => Time.zone.local(2026, 10, 12, 9, 0) })
    end

    test "lets the run go once the time it holds until has come" do
      node = wait({ "step" => "deploy", "minutes" => 30 })

      ready = travel_to(Time.zone.local(2026, 10, 12, 9, 30)) { Wait.step_type.ready?(node, {}, { "deploy" => Time.zone.local(2026, 10, 12, 9, 0) }) }

      assert ready
    end

    test "holds the run before the time it holds until" do
      node = wait({ "step" => "deploy", "minutes" => 30 })

      ready = travel_to(Time.zone.local(2026, 10, 12, 9, 29)) { Wait.step_type.ready?(node, {}, { "deploy" => Time.zone.local(2026, 10, 12, 9, 0) }) }

      assert_not ready
    end

    test "holds the run while the earlier step it counts from has no recorded time" do
      assert_not Wait.step_type.ready?(wait({ "step" => "deploy", "minutes" => 30 }), {}, {})
    end

    test "asks for the earlier step it counts from and a number of minutes, a time of day or a date" do
      fields = Wait.step_type.settings.fields

      assert_equal({ step: :previous_step, minutes: :integer, time_of_day: :string, date: :string }, fields)
    end

    test "is offered to every host's flows" do
      assert EasyFlow.registry.registered?(:wait)
    end

    test "is named after how long it waits and the step it counts from" do
      assert_equal "30 minutes after deploy", Wait.step_type.name_of(wait({ "step" => "deploy", "minutes" => 30 }))
    end

    test "is named after the time of day it waits for and the step it counts from" do
      assert_equal "09:00 after deploy", Wait.step_type.name_of(wait({ "step" => "deploy", "time_of_day" => "09:00" }))
    end

    test "is named after the date it waits for" do
      assert_equal "2026-10-20", Wait.step_type.name_of(wait({ "step" => "deploy", "date" => "2026-10-20" }))
    end
  end
end
