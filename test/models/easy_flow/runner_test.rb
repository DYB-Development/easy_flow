require "test_helper"

module EasyFlow
  class RunnerTest < ActiveSupport::TestCase
    def registry
      @registry ||= Registry.new.tap do |built|
        built.register(StepType.define(:opening) { begins_here })
        built.register(StepType.define(:ask) { setting :text, type: :string; awaits_input })
        built.register(StepType.define(:shown) do
          setting :text, type: :string
          awaits_input
          displays_by { |node| "Asked: #{node.config['text']}" }
        end)
        built.register(StepType.define(:act) { process { |node, _state| "ran #{node.id}" } })
        built.register(StepType.define(:approve) { process { |_node, _state| "yes" } })
        built.register(StepType.define(:hold) { waits_until { |node, _state| node.config["ready"] } })
        built.register(StepType.define(:fork) do
          setting :of, type: :previous_step
          route { |node, state| state[node.config["of"]] == "yes" ? "yes" : "no" }
        end)
        built.register(StepType.define(:gate) do
          setting :of, type: :string
          route { |node, state| state[node.config["of"]] == "yes" ? "yes" : "no" }
        end)
      end
    end

    def branching
      { "slug" => "r", "headline" => "A run",
        "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "first", "type" => "ask", "text" => "First?" },
                     { "id" => "gate", "type" => "gate", "of" => "first" },
                     { "id" => "yes_step", "type" => "ask", "text" => "Yes?" },
                     { "id" => "no_step", "type" => "ask", "text" => "No?" } ],
        "edges" => [ { "from" => "opening", "to" => "first" },
                     { "from" => "first", "to" => "gate" },
                     { "from" => "gate", "to" => "yes_step", "on" => "yes" },
                     { "from" => "gate", "to" => "no_step", "on" => "no" } ] }
    end

    def straight
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "first", "type" => "ask", "text" => "First?" },
                     { "id" => "second", "type" => "ask", "text" => "Second?" },
                     { "id" => "third", "type" => "ask", "text" => "Third?" } ],
        "edges" => [ { "from" => "opening", "to" => "first" }, { "from" => "first", "to" => "second" },
                     { "from" => "second", "to" => "third" } ] }
    end

    def forking
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "first", "type" => "ask", "text" => "First?" },
                     { "id" => "second", "type" => "ask", "text" => "Second?" },
                     { "id" => "fork", "type" => "fork", "of" => "first" },
                     { "id" => "yes_step", "type" => "ask", "text" => "Yes?" },
                     { "id" => "no_step", "type" => "ask", "text" => "No?" } ],
        "edges" => [ { "from" => "opening", "to" => "first" }, { "from" => "first", "to" => "second" },
                     { "from" => "second", "to" => "fork" },
                     { "from" => "fork", "to" => "yes_step", "on" => "yes" },
                     { "from" => "fork", "to" => "no_step", "on" => "no" } ] }
    end

    def showing
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "shown", "type" => "shown", "text" => "Budget?" } ],
        "edges" => [ { "from" => "opening", "to" => "shown" } ] }
    end

    def acting
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "work", "type" => "act" },
                     { "id" => "after", "type" => "ask", "text" => "After?" } ],
        "edges" => [ { "from" => "opening", "to" => "work" },
                     { "from" => "work", "to" => "after" } ] }
    end

    def holding(ready)
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "hold", "type" => "hold", "ready" => ready },
                     { "id" => "work", "type" => "act" } ],
        "edges" => [ { "from" => "opening", "to" => "hold" },
                     { "from" => "hold", "to" => "work" } ] }
    end

    def runner(document = branching)
      Runner.new(document, registry: registry)
    end

    test "stops counting at a choice the answers so far have not decided" do
      assert_equal 2, Runner.new(forking, registry: registry).questions_left({})
    end

    test "counts past a choice the answers so far have decided" do
      assert_equal 2, Runner.new(forking, registry: registry).questions_left({ "first" => "yes" })
    end

    test "counts the question being asked and every question after it" do
      assert_equal 2, Runner.new(straight, registry: registry).questions_left({ "first" => "a" })
    end

    test "stops at the first step awaiting input" do
      assert_equal "first", runner.next_step({}).id
    end

    test "carries the slug of the flow it runs" do
      assert_equal "r", runner.slug
    end

    test "carries the headline of the flow it runs" do
      assert_equal "A run", runner.headline
    end

    def gating
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "work", "type" => "approve" },
                     { "id" => "gate", "type" => "gate", "of" => "work" },
                     { "id" => "yes_step", "type" => "ask", "text" => "Yes?" },
                     { "id" => "no_step", "type" => "ask", "text" => "No?" } ],
        "edges" => [ { "from" => "opening", "to" => "work" },
                     { "from" => "work", "to" => "gate" },
                     { "from" => "gate", "to" => "yes_step", "on" => "yes" },
                     { "from" => "gate", "to" => "no_step", "on" => "no" } ] }
    end

    test "carries a process result on to a condition that reads it" do
      kept = Progress::Loose.new(nil, {}, gating)
      built = runner(gating)
      built.run(kept)

      assert_equal "yes_step", built.next_step(kept.recorded).id
    end

    def working_again
      { "nodes" => [ { "id" => "opening", "type" => "opening" },
                     { "id" => "name", "type" => "ask", "text" => "Name?" },
                     { "id" => "work", "type" => "act" },
                     { "id" => "more", "type" => "ask", "text" => "More?" },
                     { "id" => "gate", "type" => "gate", "of" => "more" },
                     { "id" => "done", "type" => "ask", "text" => "Done?" } ],
        "edges" => [ { "from" => "opening", "to" => "name" },
                     { "from" => "name", "to" => "work" },
                     { "from" => "work", "to" => "more" },
                     { "from" => "more", "to" => "gate" },
                     { "from" => "gate", "to" => "name", "on" => "yes" },
                     { "from" => "gate", "to" => "done", "on" => "no" } ] }
    end

    test "records a process in a loop against the visit it ran on, as the step it is" do
      kept = Progress::Loose.new(nil, { name: "Mowing", work: "ran work", more: "yes", "name@2": "Edging" }, working_again)
      runner(working_again).run(kept)

      assert_equal "ran work", kept.recorded[:"work@2"]
    end

    test "records what a step's process returned against that step" do
      kept = Progress::Loose.new(nil, {}, acting)
      runner(acting).run(kept)

      assert_equal "ran work", kept.recorded[:work]
    end

    test "names the template that draws the step it stops at" do
      assert_equal EasyFlow.drawing, runner.drawing_at({})
    end

    test "shows a step the way its own type declares" do
      assert_equal "Asked: Budget?", runner(showing).next_step({})
    end

    test "holds every step the flow document carries" do
      assert_equal %w[opening first gate yes_step no_step], runner.steps.map(&:id)
    end

    test "finds a step by the id it was given" do
      assert_equal "First?", runner.step("first").config["text"]
    end

    test "holds only the steps the walked path reached" do
      walked = { first: "yes", no_step: "stale", yes_step: "kept" }

      assert_equal %w[first yes_step], runner.steps_on_path(walked).map(&:id)
    end

    test "drops state stranded off the branch taken" do
      wandered = { first: "yes", no_step: "stale", yes_step: "kept" }

      assert_equal({ first: "yes", yes_step: "kept" }, runner.state_on_path(wandered))
    end

    test "stops at a step that waits until what it waits for has happened" do
      kept = Progress::Loose.new(nil, {}, holding(false))
      runner(holding(false)).run(kept)

      assert_not kept.recorded.key?(:work)
    end

    test "carries on past a waiting step once what it waits for has happened" do
      kept = Progress::Loose.new(nil, {}, holding(true))
      runner(holding(true)).run(kept)

      assert_equal "ran work", kept.recorded[:work]
    end
  end
end
