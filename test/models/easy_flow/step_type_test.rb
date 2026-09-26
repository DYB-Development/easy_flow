require "test_helper"

module EasyFlow
  class StepTypeTest < ActiveSupport::TestCase
    def node_testing(id)
      Node.new(id: "branch", type: "condition", config: { "answer" => id })
    end

    test "insists on a value for the earlier step it names" do
      step_type = StepType.define(:act) { setting :of, type: :previous_step }

      assert_equal [ :of ], step_type.settings.required
    end

    test "depends on the step its previous step setting names" do
      step_type = StepType.define(:act) { setting :of, type: :previous_step }

      assert_equal [ "earlier" ], step_type.settings.requirements_for({ "of" => "earlier" })
    end

    test "carries the template it declares" do
      step_type = StepType.define(:ask) { drawn_by "flows/steps/tiles" }

      assert_equal "flows/steps/tiles", step_type.drawn_by
    end

    test "carries the display it declares" do
      step_type = StepType.define(:ask) { displays_by { |node| node.config["text"] } }

      assert_equal "Budget?", step_type.display_of(Node.new(id: "a", type: "ask", config: { "text" => "Budget?" }))
    end

    test "carries the behaviour it declares" do
      step_type = StepType.define(:agent) { process { |node, state| { "out" => state["in"] } } }

      assert_equal({ "out" => 1 }, step_type.process(node_testing("a"), { "in" => 1 }))
    end

    test "contributes nothing when it declares no behaviour" do
      step_type = StepType.define(:agent) { }

      assert_nil step_type.process(node_testing("a"), {})
    end

    test "carries the routing it declares separately from its behaviour" do
      step_type = StepType.define(:branch) do
        route { |node, state| state["ok"] ? :yes : :no }
      end

      assert_equal :no, step_type.route(node_testing("a"), { "ok" => false })
    end

    test "chooses no port when it declares no routing" do
      step_type = StepType.define(:agent) { }

      assert_nil step_type.route(node_testing("a"), {})
    end

    test "depends on nothing when it names no earlier step" do
      step_type = StepType.define(:agent) { }

      assert_empty step_type.settings.requirements_for(node_testing("a").config)
    end

    test "awaits external input when it declares so" do
      step_type = StepType.define(:question) { awaits_input }

      assert_predicate step_type, :awaits_input?
    end

    test "does not await external input by default" do
      step_type = StepType.define(:agent) { }

      assert_not_predicate step_type, :awaits_input?
    end

    test "declares a setting naming a step that comes before it" do
      step_type = StepType.define(:branch) { setting :step, type: :previous_step }

      assert_equal :previous_step, step_type.settings.fields[:step]
    end

    test "declares a setting whose choices come from the step another setting names" do
      step_type = StepType.define(:branch) do
        setting :step, type: :previous_step
        setting :answer, from: :step
      end

      assert_equal :step, step_type.settings.drawn_from[:answer]
    end

    test "declares a named output a later step may read" do
      step_type = StepType.define(:ask) { output :answer, label: "Answer" }

      assert_equal [ :answer ], step_type.outputs.map(&:name)
    end

    test "declares the values an output may take for a given step" do
      step_type = StepType.define(:ask) { output :answer, values: ->(node) { node.config["answers"] } }
      node = Node.new(id: "q", type: "ask", config: { "answers" => [ { "value" => "high" } ] })

      assert_equal [ { "value" => "high" } ], step_type.values_of(:answer, node)
    end

    test "declares the type an output's value takes" do
      step_type = StepType.define(:ask) { output :weight, type: :integer }

      assert_equal :integer, step_type.outputs.first.type
    end

    test "reads a plain output value as a value labelled by itself" do
      step_type = StepType.define(:check) { output :result, type: :boolean, values: [ true, false ] }
      node = Node.new(id: "g", type: "check", config: {})

      assert_equal [ { "value" => true, "label" => "true" }, { "value" => false, "label" => "false" } ],
        step_type.values_of(:result, node)
    end

    test "declares an output drawing its values from the step a setting names" do
      step_type = StepType.define(:switch) { setting :step, type: :previous_step; output :choice, from: :step }

      assert_equal :step, step_type.outputs.first.from
    end

    test "declares a setting it cannot run without" do
      step_type = StepType.define(:branch) { setting :step, type: :string, required: true }

      assert_equal [ :step ], step_type.settings.required
    end

    test "can name an instance from a block over its whole config" do
      step_type = StepType.define(:branch) { names_by { |node| "#{node.config['step']} is #{node.config['answer']}" } }
      node = Node.new(id: "b", type: "branch", config: { "step" => "budget", "answer" => "high" })

      assert_equal "budget is high", step_type.name_of(node)
    end

    test "declares a setting choosing among the outputs of the step another names" do
      step_type = StepType.define(:reads) do
        setting :step, type: :previous_step
        setting :output, outputs_of: :step
      end

      assert_equal :step, step_type.settings.outputs_of[:output]
    end

    test "declares itself a step a flow ends at" do
      assert_predicate StepType.define(:stop) { ends_here }, :ends_here?
    end

    test "does not end a flow unless it says so" do
      assert_not_predicate StepType.define(:ask) { }, :ends_here?
    end

    test "declares itself a step a flow begins at" do
      assert_predicate StepType.define(:go) { begins_here }, :begins_here?
    end

    test "does not begin a flow unless it says so" do
      assert_not_predicate StepType.define(:ask) { }, :begins_here?
    end

    test "can declare which field names an instance of it" do
      step_type = StepType.define(:ask) { setting :text, type: :string; names_by :text }

      assert_equal :text, step_type.naming_field
    end

    test "names an instance by nothing unless it says so" do
      step_type = StepType.define(:branch) { setting :answer, type: :string }

      assert_nil step_type.naming_field
    end

    test "declares a setting holding a repeating group" do
      step_type = StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer } }

      assert_equal :list, step_type.settings.fields[:options]
    end

    test "carries what each record in the list holds" do
      step_type = StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :string; setting :weight, type: :integer } }

      assert_equal({ value: :string, weight: :integer }, step_type.settings.record_fields[:options])
    end

    test "refuses a list of records that does not say what a record holds" do
      assert_raises UnknownFieldType do
        StepType.define(:ask) { setting :options, type: :list }
      end
    end

    test "refuses a record holding a type outside the vocabulary" do
      assert_raises UnknownFieldType do
        StepType.define(:ask) { setting(:options, type: :list) { setting :value, type: :wormhole } }
      end
    end

    test "carries the fields it declares" do
      step_type = StepType.define(:agent) { setting :prompt, type: :string }

      assert_equal({ prompt: :string }, step_type.settings.fields)
    end

    test "refuses a field type outside the vocabulary" do
      assert_raises UnknownFieldType do
        StepType.define(:agent) { setting :prompt, type: :wormhole }
      end
    end

    test "carries the label it was given" do
      step_type = StepType.define(:agent) { step_name "Agent call" }

      assert_equal "Agent call", step_type.step_name
    end

    test "falls back to its identifier when no label is given" do
      step_type = StepType.define(:agent) { }

      assert_equal "agent", step_type.step_name
    end

    test "carries the identifier it was defined with" do
      step_type = StepType.define(:agent) { step_name "Agent call" }

      assert_equal :agent, step_type.id
    end

    test "declares a configurable value with setting" do
      step_type = StepType.define(:probe) { setting :prompt, type: :string }

      assert_equal({ prompt: :string }, step_type.settings.fields)
    end

    test "refuses a setting whose type it does not know" do
      assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :prompt, type: :nonsense } }
    end

    test "refuses a repeating group that does not say what an entry holds" do
      assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :answers, type: :records } }
    end

    test "refuses the text type in favour of string" do
      assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :prompt, type: :text } }
    end

    test "refuses the number type in favour of integer and float" do
      assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :weight, type: :number } }
    end

    test "refuses an unknown type inside a repeating group" do
      assert_raises(UnknownFieldType) do
        StepType.define(:probe) { setting(:answers, type: :list) { setting :weight, type: :number } }
      end
    end

    test "declares what each entry of a list holds" do
      step_type = StepType.define(:ask) do
        setting :answers, type: :list do
          setting :value, type: :string
          setting :weight, type: :integer
        end
      end

      assert_equal({ value: :string, weight: :integer }, step_type.settings.record_fields[:answers])
    end

    test "declares the name a step type is known by" do
      step_type = StepType.define(:ask) { step_name "Question" }

      assert_equal "Question", step_type.step_name
    end

    test "labels a setting after its key" do
      step_type = StepType.define(:ask) { setting :question, type: :string }

      assert_equal "Question", step_type.settings.labels[:question]
    end

    test "prefers a label a setting states for itself" do
      step_type = StepType.define(:ask) { setting :tag, type: :string, label: "Grouping tag" }

      assert_equal "Grouping tag", step_type.settings.labels[:tag]
    end

    test "stores an integer setting as a number" do
      step_type = StepType.define(:ask) { setting :weight, type: :integer }

      assert_equal({ "weight" => 5 }, step_type.settings.coerce("weight" => "5"))
    end

    test "stores a list entry's integer as a number" do
      step_type = StepType.define(:ask) do
        setting :options, type: :list do
          setting :value, type: :string
          setting :weight, type: :integer
        end
      end

      coerced = step_type.settings.coerce("options" => [ { "value" => "low", "weight" => "3" } ])

      assert_equal 3, coerced["options"].first["weight"]
    end

    test "refuses a multi select that offers no options" do
      assert_raises(UnknownFieldType) { StepType.define(:probe) { setting :channels, type: :multi_select } }
    end

    test "objects to a value outside the options it offers" do
      step_type = StepType.define(:probe) { setting :channels, type: :multi_select, options: %w[email sms] }

      assert_equal [ "Channels does not offer post" ], step_type.settings.objections("channels" => %w[email post])
    end

    test "objects to more choices than its limit allows" do
      step_type = StepType.define(:probe) { setting :channels, type: :multi_select, options: %w[a b c], limit: 2 }

      assert_equal [ "Channels takes at most 2" ], step_type.settings.objections("channels" => %w[a b c])
    end

    test "objects to more list entries than its limit allows" do
      step_type = StepType.define(:probe) do
        setting :answers, type: :list, limit: 1 do
          setting :value, type: :string
        end
      end

      assert_equal [ "Answers takes at most 1" ], step_type.settings.objections("answers" => [ { "value" => "a" }, { "value" => "b" } ])
    end

    test "objects with the message a check returns" do
      step_type = StepType.define(:probe) do
        setting :channels, type: :multi_select, options: %w[a b],
          check: ->(chosen) { "Channels needs at least one" if chosen.empty? }
      end

      assert_equal [ "Channels needs at least one" ], step_type.settings.objections("channels" => [])
    end

    test "accepts a value its check returns nothing for" do
      step_type = StepType.define(:probe) do
        setting :channels, type: :multi_select, options: %w[a b],
          check: ->(chosen) { "Channels needs at least one" if chosen.empty? }
      end

      assert_empty step_type.settings.objections("channels" => %w[a])
    end

    test "a select offers the options its lookup returns when they are read" do
      offered = %w[small]
      step_type = StepType.define(:probe) { setting :size, type: :select, options: -> { offered } }
      offered << "large"

      assert_equal %w[small large], step_type.settings.choices[:size]
    end

    test "a step type says what is wrong with an answer its check refuses" do
      step_type = StepType.define(:probe) { answer_check { |_node, value| "Too short" if value.to_s.size < 3 } }

      assert_equal "Too short", step_type.answer_problem(Node.new(id: "a", type: "probe", config: {}), "ab")
    end
  end
end
