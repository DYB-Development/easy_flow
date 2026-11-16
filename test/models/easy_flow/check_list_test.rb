require "test_helper"

module EasyFlow
  class CheckListTest < ActiveSupport::TestCase
    test "adds an ok row for a check that found nothing" do
      assert_includes CheckList.new([], checks: []).rows, { "level" => "ok", "node" => nil, "sentence" => "Every connection joins two steps that exist." }
    end
  end
end
