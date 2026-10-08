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

    test "reads back the labels of every answer ticked on a checklist" do
      ticking = { "slug" => "t", "entry" => "conditions",
                  "nodes" => [ { "id" => "conditions", "type" => "checklist", "question" => "What must they do?",
                                 "answers" => [ { "value" => "proof", "label" => "Shows proof" }, { "value" => "on_time", "label" => "Pays on time" } ] } ] }

      assert_equal "Shows proof and Pays on time", runner(ticking).choice_label("conditions", [ "proof", "on_time" ])
    end

    test "labels a file step's answer by the name of the file the host kept" do
      stored_with = EasyFlow.file_store
      EasyFlow.file_store = Class.new do
        def name_of(reference)
          "guide.pdf" if reference == "kept-1"
        end
      end.new
      uploading = { "slug" => "u", "entry" => "guide", "nodes" => [ { "id" => "guide", "type" => "file_upload", "question" => "Upload the guide" } ] }

      assert_equal "guide.pdf", runner(uploading).choice_label(:guide, "kept-1")
    ensure
      EasyFlow.file_store = stored_with
    end
  end
end
