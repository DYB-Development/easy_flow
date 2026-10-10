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
  end
end
