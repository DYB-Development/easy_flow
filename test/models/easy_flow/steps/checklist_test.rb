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
    end
  end
end
