require "test_helper"

module EasyFlow
  class RunViewTest < ActiveSupport::TestCase
    def version
      @version ||= Definition.create!(host: "dummy", slug: "run-view").record_definition(flowing(
        "entry" => "outline",
        "nodes" => [ { "id" => "outline", "type" => "question", "question" => "Outline", "answers" => [ { "value" => "on" } ] },
                     { "id" => "end", "type" => "terminal" } ],
        "edges" => [ { "from" => "outline", "to" => "end" } ]
      ))
    end

    def drawn(steps = {}, selected: nil)
      RunView.new(version, steps: steps, selected: selected).to_h
    end

    def step(id, steps = {})
      drawn(steps)["nodes"].find { |node| node["id"] == id }
    end

    test "gives each step the state its host supplied" do
      assert_equal "paused", step("outline", "outline" => { state: :paused })["state"]
    end
  end
end
