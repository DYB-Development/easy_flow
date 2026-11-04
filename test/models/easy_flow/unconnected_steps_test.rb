require "test_helper"

module EasyFlow
  class UnconnectedStepsTest < ActiveSupport::TestCase
    def asking(id, **config)
      { "id" => id, "type" => "question", "question" => id, "answers" => [ { "value" => "yes" } ] }.merge(config.transform_keys(&:to_s))
    end

    def checked(nodes, edges = [])
      UnconnectedSteps.new(Document.new(flowing({ "entry" => "a", "nodes" => [ asking("a"), { "id" => "end", "type" => "terminal" } ] + nodes,
                                                  "edges" => [ { "from" => "a", "to" => "end" } ] + edges })))
    end

    test "a problem only on a step being removed is no objection" do
      assert_empty checked([ { "id" => "aside", "type" => "question" } ]).objections
    end
  end
end
