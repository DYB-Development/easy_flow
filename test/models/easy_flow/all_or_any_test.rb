require "test_helper"

module EasyFlow
  class AllOrAnyTest < ActiveSupport::TestCase
    def joined(join, comparisons)
      Node.new(id: "join", type: "all_or_any", config: { "join" => join, "comparisons" => comparisons })
    end

    def coverage_and_warnings
      [ { "step" => "tests", "output" => "coverage", "comparison" => "at least", "other_step" => "baseline", "other_output" => "coverage" },
        { "step" => "tests", "output" => "warnings", "comparison" => "less than", "other_step" => "baseline", "other_output" => "warnings" } ]
    end

    test "follows its true route under all of when every comparison holds" do
      state = { "tests" => { "coverage" => 91, "warnings" => 2 }, "baseline" => { "coverage" => 85, "warnings" => 5 } }

      assert_equal true, AllOrAny.step_type.route(joined("all of", coverage_and_warnings), state)
    end

    test "follows its false route under all of when one comparison does not hold" do
      state = { "tests" => { "coverage" => 91, "warnings" => 9 }, "baseline" => { "coverage" => 85, "warnings" => 5 } }

      assert_equal false, AllOrAny.step_type.route(joined("all of", coverage_and_warnings), state)
    end
  end
end
