require "test_helper"

module EasyFlow
  class QuestionRunnerTest < ActiveSupport::TestCase
    def asking
      { "slug" => "r", "headline" => "A run", "entry" => "first",
        "nodes" => [ { "id" => "first", "type" => "question", "question" => "Budget?",
                       "answers" => [ { "value" => "low", "label" => "Not much" }, { "value" => "high" } ] } ] }
    end

    def runner(document = asking)
      QuestionRunner.new(flowing(document))
    end

    test "displays the step it stops at as what that step asks" do
      assert_equal "Budget?", runner.next_step({}).text
    end

    test "offers a choice for each answer the step lists" do
      assert_equal %w[low high], runner.next_step({}).choices.map(&:value)
    end

    test "labels a choice by the label it carries" do
      assert_equal "Not much", runner.next_step({}).choices.first.label
    end

    test "labels a choice carrying no label of its own by its value" do
      assert_equal "high", runner.next_step({}).choices.last.label
    end

    test "reads back the text a step asked" do
      assert_equal "Budget?", runner.question_text("first")
    end

    test "reads back the label of the choice that was taken" do
      assert_equal "Not much", runner.choice_label("first", "low")
    end

    test "reads back a taken value no choice offers as itself" do
      assert_equal "unknown", runner.choice_label("first", "unknown")
    end
  end
end
