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

    def grouped
      Definition.create!(host: "dummy", slug: "run-view-grouped").record_definition(flowing(
        "entry" => "variants",
        "nodes" => [ { "id" => "variants", "type" => "for_each", "list" => "outline.variants", "concurrency" => 3, "holds" => [ "write" ] },
                     { "id" => "write", "type" => "question", "question" => "Write", "answers" => [ { "value" => "on" } ] } ],
        "edges" => [ { "from" => "variants", "to" => "write" } ]
      ))
    end

    def group
      RunView.new(grouped).to_h["nodes"].find { |node| node["id"] == "variants" }
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

    test "draws the steps a flow starts and ends at" do
      assert_equal %w[start outline draft end], drawn["nodes"].map { |node| node["id"] }
    end

    test "shows the Start step as done once any step of the run has left pending" do
      assert_equal "done", step("start", "outline" => { state: :paused }, "draft" => { state: :pending })["state"]
    end

    test "shows the End step the run ended at as done" do
      ended = RunView.new(version, steps: { "draft" => { state: :done } }, ended_at: :end).to_h["nodes"].find { |node| node["id"] == "end" }

      assert_equal "done", ended["state"]
    end

    test "shows an End step the run did not end at as pending" do
      assert_equal "pending", step("end", "draft" => { state: :done })["state"]
    end

    test "gives the Start and End steps no address, since they have no page of their own" do
      shown = drawn({ "start" => { address: "/runs/1/start" }, "end" => { address: "/runs/1/end" } })["nodes"]

      assert_equal [ nil, nil ], shown.values_at(0, -1).map { |node| node["address"] }
    end

    test "leaves out the Start and End steps when its host chooses to hide them" do
      assert_equal %w[outline draft], RunView.new(version, start_and_end: false).to_h["nodes"].map { |node| node["id"] }
    end

    test "places each step after the step that leads to it" do
      assert_operator step("draft")["row"], :>, step("outline")["row"]
    end

    test "lists the steps a group step holds" do
      assert_equal [ "write" ], group["holds"]
    end

    test "gives a group step its settings and their types for its header line" do
      assert_equal({ "config" => { "list" => "outline.variants", "concurrency" => 3, "holds" => [ "write" ] },
                     "fields" => { "list" => "string", "concurrency" => "integer", "on_item_failure" => "select" } },
                   group.slice("config", "fields"))
    end

    test "names the step its host chose as selected" do
      assert_equal "draft", drawn(selected: :draft)["selected"]
    end

    test "joins each step to the step it leads to" do
      assert_includes drawn["edges"].map { |edge| edge.slice("source", "target") }, { "source" => "outline", "target" => "draft" }
    end
  end
end
