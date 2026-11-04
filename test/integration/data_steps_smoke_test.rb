require "test_helper"

module EasyFlow
  class DataStepsSmokeTest < ActionDispatch::IntegrationTest
    class Shelf
      def reads
        %w[stock]
      end

      def writes
        %w[note]
      end

      def carry_out(name, values)
        return values["title"] if name == "note"
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
  end
end
