require "test_helper"

module EasyFlow
  module Steps
    class ChecklistTest < ActiveSupport::TestCase
      test "displays itself as what it asks and the answers it offers to tick" do
        node = Node.new(id: "conditions", type: "checklist", config: { "question" => "What must they do?",
          "answers" => [ { "value" => "proof", "label" => "Shows proof" }, { "value" => "on_time", "label" => "Pays on time" } ] })

        displayed = Checklist.step_type.display_of(node)

        assert_equal [ "What must they do?", [ "proof", "on_time" ] ], [ displayed.text, displayed.choices.map(&:value) ]
      end

      test "a required checklist refuses an answer with nothing ticked" do
        node = Node.new(id: "conditions", type: "checklist", config: { "required" => true })

        assert_equal "Tick at least one to go on.", Checklist.step_type.answer_problem(node, [ "" ])
      end

      test "an answer carries info the canvas offers for editing" do
        assert_equal :string, Checklist.step_type.settings.record_fields[:answers][:info]
      end
    end
  end
end
