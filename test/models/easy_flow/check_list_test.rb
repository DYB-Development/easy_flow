require "test_helper"

module EasyFlow
  class CheckListTest < ActiveSupport::TestCase
    test "adds an ok row for a check that found nothing" do
      assert_includes CheckList.new([], checks: []).rows, { "level" => "ok", "node" => nil, "sentence" => "Every connection joins two steps that exist." }
    end

    test "leaves out the ok row of a check that found a problem" do
      found = [ { "node" => "a", "problem" => "missing_edge_target", "sentence" => "A leads to a step that is not there." } ]

      assert_not_includes CheckList.new(found, checks: []).rows.map { |row| row["sentence"] }, "Every connection joins two steps that exist."
    end

    test "adds the ok row of an optional check only when it is turned on" do
      assert_equal [ false, true ], [ [], [ :dead_end ] ].map { |checks| CheckList.new([], checks: checks).rows.any? { |row| row["sentence"] == "Every path ends at an End step." } }
    end
  end
end
