require "test_helper"

module EasyFlow
  class RunViewTest < ActiveSupport::TestCase
    def version
      @version ||= Definition.create!(host: "dummy", slug: "run-view").record_definition(flowing(
        "entry" => "outline",
        "nodes" => [ { "id" => "outline", "type" => "question", "question" => "Outline", "answers" => [ { "value" => "on" } ] },
                     { "id" => "draft", "type" => "question", "question" => "Draft", "answers" => [ { "value" => "on" } ] },
                     { "id" => "end", "type" => "terminal" } ],
        "edges" => [ { "from" => "outline", "to" => "draft" }, { "from" => "draft", "to" => "end" } ]
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

    test "gives each step the status line, address and version its host supplied" do
      shown = step("outline", "outline" => { state: :done, status: "8.2s · $0.04", address: "/runs/1/outline", version: "v9" })

      assert_equal({ "status" => "8.2s · $0.04", "address" => "/runs/1/outline", "version" => "v9" }, shown.slice("status", "address", "version"))
    end

    test "names each step and its type code" do
      assert_equal({ "type" => "question", "label" => "Outline" }, step("outline").slice("type", "label"))
    end

    test "leaves out the steps a flow starts and ends at" do
      assert_equal %w[outline draft], drawn["nodes"].map { |node| node["id"] }
    end

    test "places each step after the step that leads to it" do
      assert_operator step("draft")["row"], :>, step("outline")["row"]
    end

    test "joins each step to the step it leads to" do
      assert_includes drawn["edges"].map { |edge| edge.slice("source", "target") }, { "source" => "outline", "target" => "draft" }
    end
  end
end
