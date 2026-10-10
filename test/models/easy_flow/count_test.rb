require "test_helper"

module EasyFlow
  class CountTest < ActiveSupport::TestCase
    def count(config)
      Node.new(id: "tries", type: "count", config: config)
    end

    test "records how many times the earlier step has been visited when no answer is picked" do
      node = count({ "step" => "tests" })

      assert_equal 3, Count.step_type.process(node, { "tests" => "failed", "tests@2" => "failed", "tests@3" => "passed" })
    end

    test "records how many visits to the earlier step gave the answer picked" do
      node = count({ "step" => "tests", "answer" => "failed" })

      assert_equal 2, Count.step_type.process(node, { "tests" => "failed", "tests@2" => "passed", "tests@3" => "failed" })
    end

    test "reads the answer from the output picked when the earlier step recorded several" do
      node = count({ "step" => "tests", "output" => "result", "answer" => "failed" })

      assert_equal 1, Count.step_type.process(node, { "tests" => { "result" => "failed", "took" => 4 }, "tests@2" => { "result" => "passed", "took" => 3 } })
    end

    test "offers the earlier step's outputs to pick the answer from" do
      assert_equal :step, Count.step_type.settings.outputs_of[:output]
    end

    test "draws the answer it counts from the output picked" do
      assert_equal :output, Count.step_type.settings.drawn_from[:answer]
    end

    test "declares the count it records as a whole-number output" do
      assert_equal [ [ :count, :integer ] ], Count.step_type.outputs.map { |output| [ output.name, output.type ] }
    end

    test "is named after the step and the answer it counts" do
      assert_equal "Count tests failed", Count.step_type.name_of(count({ "step" => "tests", "answer" => "failed" }))
    end

    def registry
      @registry ||= Registry.new.tap do |built|
        [ Start, Terminal, Count, Compare ].each { |step| step.register(built) }
        built.register(StepType.define(:ask) { awaits_input })
      end
    end

    def retry_loop
      { "slug" => "retry", "headline" => "Retry",
        "nodes" => [ { "id" => "start", "type" => "start" },
                     { "id" => "tests", "type" => "ask" },
                     { "id" => "tries", "type" => "count", "step" => "tests", "answer" => "failed" },
                     { "id" => "enough", "type" => "compare", "step" => "tries", "comparison" => "at least", "amount" => 3 },
                     { "id" => "gave_up", "type" => "terminal", "output" => "gave up" } ],
        "edges" => [ { "from" => "start", "to" => "tests" },
                     { "from" => "tests", "to" => "tries" },
                     { "from" => "tries", "to" => "enough" },
                     { "from" => "enough", "to" => "gave_up", "on" => "true" },
                     { "from" => "enough", "to" => "tests", "on" => "false" } ] }
    end

    def run_retry_loop(answers)
      Progress::Loose.new(nil, answers, retry_loop).tap { |progress| Runner.new(retry_loop, registry: registry).run(progress) }
    end

    test "a Compare step routes on the count a Count step recorded" do
      recorded = run_retry_loop({ tests: "failed", "tests@2": "failed", "tests@3": "failed" }).recorded

      assert_equal "gave up", Digest.new(Document.new(retry_loop, registry: registry), registry: registry).output(recorded.transform_keys(&:to_s))
    end

    test "is offered to every host's flows" do
      assert EasyFlow.registry.registered?(:count)
    end
  end
end
