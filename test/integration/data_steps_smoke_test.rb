require "test_helper"

module EasyFlow
  class DataStepsSmokeTest < ActionDispatch::IntegrationTest
    class Shelf
      def reads
        %w[stock item]
      end

      def writes
        %w[note mark]
      end

      def carry_out(name, values)
        return values["title"] if name == "note"
        return values["item"] if %w[item mark].include?(name)
        raise "No such item" unless values["sku"] == "good"

        { title: "Boots" }
      end
    end

    setup { EasyFlow.data_source = Shelf.new }
    teardown { EasyFlow.data_source = nil }

    def flow
      nodes = [ { "id" => "start", "type" => "start" },
                { "id" => "pick", "type" => "question", "question" => "Which?", "answers" => [ { "value" => "bad" }, { "value" => "good" } ] },
                { "id" => "lookup", "type" => "read_data", "data" => "stock", "values" => [ { "name" => "title" } ],
                  "inputs" => [ { "name" => "sku", "step" => "pick", "output" => "answer" } ] },
                { "id" => "log", "type" => "write_data", "data" => "note", "inputs" => [ { "name" => "title", "step" => "lookup", "output" => "title" } ] },
                { "id" => "done", "type" => "terminal", "output" => "finished" } ]
      edges = [ { "from" => "start", "to" => "pick" }, { "from" => "pick", "to" => "lookup" },
                { "from" => "lookup", "to" => "pick", "on" => "failed" }, { "from" => "lookup", "to" => "log", "on" => "passed" },
                { "from" => "log", "to" => "done", "on" => "passed" }, { "from" => "log", "to" => "done", "on" => "failed" } ]

      Definition.create!(host: "dummy", slug: "stock-check", persists: :each_step).tap do |built|
        built.publish_version(built.definition_versions.create!(number: 1, definition: { "slug" => "stock-check", "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def publishing(slug, persists, nodes, edges)
      Definition.create!(host: "dummy", slug: slug, persists: persists).tap do |built|
        built.publish_version(built.definition_versions.create!(number: 1, definition: { "slug" => slug, "entry" => "start", "nodes" => nodes, "edges" => edges }))
      end
    end

    def owner_input
      [ { "name" => "item", "from_run_owner" => true } ]
    end

    def owner_flow(slug)
      nodes = [ { "id" => "start", "type" => "start" },
                { "id" => "read", "type" => "read_data", "data" => "item", "inputs" => owner_input },
                { "id" => "write", "type" => "write_data", "data" => "mark", "inputs" => owner_input },
                { "id" => "done", "type" => "terminal" } ]
      edges = [ { "from" => "start", "to" => "read" },
                { "from" => "read", "to" => "write", "on" => "passed" }, { "from" => "read", "to" => "done", "on" => "failed" },
                { "from" => "write", "to" => "done", "on" => "passed" }, { "from" => "write", "to" => "done", "on" => "failed" } ]

      publishing(slug, :each_step, nodes, edges)
    end

    def run_answering(*answers)
      Run.start(flow).tap do |run|
        answers.each do |answer|
          run.record(run.next_step(run.recorded).id, answer)
          run.advance
        end
      end
    end

    test "a read that does not work records why and moves along its failed connection" do
      run = run_answering("bad")

      assert_equal [ "No such item", "pick@2" ], [ run.recorded[:lookup]["reason"], run.next_step(run.recorded).id ]
    end

    test "a read in a loop takes the latest answer and a later write reads what it recorded" do
      run = run_answering("bad", "good")

      assert_equal "Boots", run.recorded[:log]["answer"]
    end

    test "a run whose reads and writes work moves along their passed connections to the end" do
      assert run_answering("good").ended_at_end?
    end

    test "a stored run gives its owner's id to its read data step" do
      owner = Definition.create!(host: "dummy", slug: "the-owner")
      run = Run.start(owner_flow("owner-read")).tap { |started| started.update!(owner: owner) }

      run.advance

      assert_equal owner.id, run.recorded[:read]["answer"]
    end

    test "a stored run gives its owner's id to its write data step" do
      owner = Definition.create!(host: "dummy", slug: "the-owner")
      run = Run.start(owner_flow("owner-write")).tap { |started| started.update!(owner: owner) }

      run.advance

      assert_equal owner.id, run.recorded[:write]["answer"]
    end

    test "a run started by a Flow step gives its parent's owner's id to its read data step" do
      owner = Definition.create!(host: "dummy", slug: "the-owner")
      nodes = [ { "id" => "start", "type" => "start" }, { "id" => "inner", "type" => "flow_step", "flow" => owner_flow("owner-inner").id.to_s, "version" => 1 }, { "id" => "done", "type" => "terminal" } ]
      parent = Run.start(publishing("owner-parent", :each_step, nodes, [ { "from" => "start", "to" => "inner" }, { "from" => "inner", "to" => "done" } ]))
      parent.update!(owner: owner)

      parent.advance

      assert_equal owner.id, parent.inner_runs.first.recorded[:read]["answer"]
    end

    test "a stored run with no owner gives its read data step no value and still follows passed" do
      run = Run.start(owner_flow("owner-none"))

      run.advance

      assert_equal "passed", run.recorded[:read]["result"]
    end

    test "a flow that saves no run tells the visitor it cannot read data and goes no further" do
      unsaved = flow.tap { |built| built.update!(persists: :unsaved) }

      get easy_flow.flow_step_path(unsaved.slug), params: { asked: "pick", answers: { pick: "good" } }

      assert_equal [ true, false ], [ response.body.include?("Data can only be read or written in a flow that saves its runs."), response.body.include?("Boots") ]
    end
  end
end
