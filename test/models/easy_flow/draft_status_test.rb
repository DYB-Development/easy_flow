require "test_helper"

module EasyFlow
  class DraftStatusTest < ActiveSupport::TestCase
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "status").tap do |built|
        built.record_definition(flowing("slug" => "status", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "answers" => [ { "value" => "yes" } ] },
                       { "id" => "b", "type" => "question", "answers" => [ { "value" => "yes" } ] } ],
          "edges" => []))
      end
    end

    def rename(id, question)
      document = Document.new(flow.document)
      flow.edit_history.record(document.configure(id, "question" => question, "answers" => [ { "value" => "yes" } ]), :updated, [ id ], document.to_h)
    end

    test "names the version the draft is based on and how many changes it has since" do
      rename("a", "First")
      rename("b", "Second")

      assert_equal "draft from v1 · unsaved 2 changes", DraftStatus.new(flow.reload).to_s
    end

    test "counts a single change as one change" do
      rename("a", "First")

      assert_equal "draft from v1 · unsaved 1 change", DraftStatus.new(flow.reload).to_s
    end
  end
end
