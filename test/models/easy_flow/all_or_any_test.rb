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

    test "follows its true route under any of when one comparison holds" do
      state = { "tests" => { "coverage" => 91, "warnings" => 9 }, "baseline" => { "coverage" => 85, "warnings" => 5 } }

      assert_equal true, AllOrAny.step_type.route(joined("any of", coverage_and_warnings), state)
    end

    test "compares a comparison that names no second step against its amount alone" do
      comparison = { "step" => "tests", "output" => "coverage", "comparison" => "at least", "amount" => 80 }

      assert_equal true, AllOrAny.step_type.route(joined("all of", [ comparison ]), { "tests" => { "coverage" => 91 } })
    end

    test "follows its false route while it holds no comparisons" do
      assert_equal false, AllOrAny.step_type.route(joined("all of", []), {})
    end

    test "asks whether all of or any of its comparisons must hold, and for the comparisons" do
      assert_equal({ join: :select, comparisons: :list }, AllOrAny.step_type.settings.fields)
    end

    test "asks each comparison for a step, its output, a comparison, and an amount or a second step's output" do
      expected = { step: :previous_step, output: :from_step, comparison: :select, amount: :float, other_step: :previous_step, other_output: :from_step }

      assert_equal({ comparisons: expected }, AllOrAny.step_type.settings.record_fields)
    end

    test "declares the true or false result it decides as an output" do
      assert_equal [ true, false ], AllOrAny.step_type.values_of(:result, joined("all of", [])).map { |value| value["value"] }
    end
  end
end
