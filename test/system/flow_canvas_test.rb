require "application_system_test_case"

module EasyFlow
  class FlowCanvasTest < ApplicationSystemTestCase
    def flow
      @flow ||= Definition.create!(slug: "canvas-system").tap do |built|
        built.record_definition(flowing(
          "slug" => "canvas-system", "entry" => "first",
          "nodes" => [ { "id" => "first", "type" => "question", "question" => "First",
                         "answers" => [ { "value" => "yes", "label" => "Yes please" } ] },
                       { "id" => "gate", "type" => "condition", "step" => "first", "output" => "answer", "comparison" => "is", "answer" => "yes" },
                       { "id" => "yes_step", "type" => "question", "question" => "Yes path",
                         "answers" => [ { "value" => "on" } ] } ],
          "edges" => [ { "from" => "first", "to" => "gate" },
                       { "from" => "gate", "to" => "yes_step", "on" => true } ]
        ))
      end
    end

    def wired
      @wired ||= Definition.create!(slug: "canvas-wired").tap do |built|
        built.record_definition(flowing(
          "slug" => "canvas-wired", "entry" => "first",
          "nodes" => [ { "id" => "first", "type" => "question", "question" => "First",
                         "answers" => [ { "value" => "yes", "label" => "Yes please" } ] },
                       { "id" => "gate", "type" => "condition", "step" => "first", "output" => "answer", "comparison" => "is", "answer" => "yes" },
                       { "id" => "yes_step", "type" => "question", "question" => "Yes path",
                         "answers" => [ { "value" => "on" } ] },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "first", "to" => "gate" },
                       { "from" => "gate", "to" => "yes_step", "on" => true },
                       { "from" => "gate", "to" => "yes_step", "on" => false },
                       { "from" => "yes_step", "to" => "end" } ]
        ))
      end
    end

    def adrift
      flow.tap do |built|
        built.record_definition(built.definition.merge(
          "nodes" => built.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))
      end
    end

    def drawn_connectors
      all("[data-connector]").map { |connector| connector["data-connector"] }
    end

    def add_step_named(label)
      find("div[style*='z-index: 9']").click_button(label, match: :first)
    end

    def long_flow
      steps = (1..12).map { |n| { "id" => "s#{n}", "type" => "question", "question" => "Step #{n}", "answers" => [ { "value" => "on" } ] } }
      links = (1...12).map { |n| { "from" => "s#{n}", "to" => "s#{n + 1}" } }

      Definition.create!(slug: "long-flow").tap do |built|
        built.record_definition(flowing("slug" => "long-flow", "entry" => "s1", "nodes" => steps, "edges" => links))
      end
    end

    test "the connector layer covers a flow taller than the window" do
      canvas_for(long_flow)

      covered = page.evaluate_script(<<~JS)
        (() => {
          const svg = document.querySelector("[data-flow-canvas] svg")
          const surface = svg.parentElement
          const lowest = Math.max(...[...surface.querySelectorAll("[data-step]")].map((c) => c.offsetTop + c.offsetHeight))
          return svg.getBoundingClientRect().height >= lowest
        })()
      JS

      assert covered, "the connector layer stops short of the flow, so lower arrows cannot reach their steps"
    end

    test "draws every step in the flow" do
      canvas_for(flow)

      assert_equal [ "start", "first", "gate", "yes_step" ], step_ids
    end

    test "draws a connector for every edge" do
      canvas_for(flow)

      assert_equal [ "start-first", "first-gate", "gate-yes_step" ], drawn_connectors
    end

    test "labels a step by the field its type names it with" do
      canvas_for(flow)

      assert_text "First"
    end

    test "marks a step that cannot be reached" do
      flow.record_definition(flow.definition.merge(
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))

      canvas_for(flow)

      assert_selector "[data-step='adrift']", text: "unreachable"
    end

    test "adding a step from an unconnected branch wires it to that branch" do
      canvas_for(flow)

      find("[data-placeholder='gate--false']").click
      add_step_named("Question")

      assert_selector "[data-step='question']"
    end

    test "removing a connection unlinks the two steps" do
      canvas_for(flow)

      find("[data-connector='first-gate']").hover
      find("[data-connector='first-gate']").click_button("×")

      assert_no_selector "[data-connector='first-gate']"
    end

    test "inserting a step on a connector puts it between the two" do
      canvas_for(flow)

      find("[data-connector='first-gate']").hover
      find("[data-connector='first-gate']").click_button("+")
      add_step_named("Question")

      assert_selector "[data-connector='first-question']"
    end

    test "opening a step labels each setting its type declares" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector]", text: "Step"
      assert_selector "[data-inspector]", text: "Answer"
    end

    test "opening a condition offers the steps that come before it" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector] select option", text: "First"
    end

    test "opening a condition offers the answers of the step it names" do
      canvas_for(flow)

      step_card("gate").click

      assert_selector "[data-inspector] select option", text: "Yes please"
    end

    test "a connector says which result it leaves on" do
      canvas_for(flow)

      assert_selector "[data-link-label]", text: "true", count: 1
    end

    test "the step a flow ends at offers nowhere to connect on from" do
      canvas_for(wired)

      assert_no_selector "[data-step='end'] button"
    end

    test "the step a flow ends at simply says it ends" do
      canvas_for(wired)

      assert_selector "[data-step='end']", text: "End"
    end

    test "a step can be added to a flow that already has steps" do
      canvas_for(flow)

      find("[title='Add a step']").click
      add_step_named("Question")

      assert_selector "[data-loose] [data-step='question']"
    end

    test "the step a flow begins at simply says it begins" do
      canvas_for(wired)

      assert_selector "[data-step='start']", text: "Start"
    end

    test "the step a flow begins at is not a place to drop another step" do
      canvas_for(wired)

      assert_no_selector "[data-step='start'][draggable='true']"
    end

    test "a step that simply leads on offers no connection to arm" do
      canvas_for(wired)

      assert_no_selector "[data-step='yes_step'] button"
    end

    test "a result with nowhere to go waits as a placeholder" do
      canvas_for(flow)

      assert_selector "[data-placeholder='gate--false']", text: "false"
    end

    test "a step nothing leads to waits beside the flow" do
      canvas_for(adrift)

      assert_selector "[data-loose] [data-step='adrift']"
    end

    test "a step the flow leads to is drawn in the flow" do
      canvas_for(adrift)

      assert_no_selector "[data-loose] [data-step='gate']"
    end

    test "an arrow reaches the placeholder a result has not filled" do
      canvas_for(flow)

      assert_selector "svg path[data-link^='gate-gate--false']"
    end

    test "a placeholder's arrow offers nothing to insert into or remove" do
      canvas_for(flow)

      assert_no_selector "[data-connector='gate-gate--false']", visible: :all
    end

    test "the step a flow ends at can be picked up and moved" do
      canvas_for(wired)

      assert_selector "[data-step='end'][draggable='true']"
    end

    test "the step a flow ends at can be deleted" do
      canvas_for(wired)

      step_card("end").click
      find("[data-inspector]").click_button("Delete step")

      assert_no_selector "[data-step='end']"
    end

    test "dragging a step onto a waiting spot fills it" do
      canvas_for(adrift)

      step_card("adrift").drag_to(find("[data-placeholder='gate--false']"))

      assert_selector "[data-connector='gate-adrift']"
    end

    test "closing the panel leaves the flow drawn" do
      canvas_for(flow)
      step_card("gate").click

      find("[data-inspector]").click_button("×")

      assert_equal [ "start-first", "first-gate", "gate-yes_step" ], drawn_connectors
    end

    test "editing a field saves when the field is left" do
      canvas_for(flow)
      step_card("first").click

      fill_in_first_field_with("Changed by hand")

      assert_selector "[data-step='first']", text: "Changed by hand"
    end

    test "dragging a step onto a connector splices it in there" do
      flow.record_definition(flow.definition.merge(
        "nodes" => flow.definition["nodes"] + [ { "id" => "adrift", "type" => "question", "question" => "Adrift" } ]))
      canvas_for(flow)

      step_card("adrift").drag_to(find("[data-connector='first-gate']"))

      assert_selector "[data-connector='first-adrift']"
    end

    test "undoing puts back the connection that was removed" do
      canvas_for(flow)
      find("[data-connector='first-gate']").hover
      find("[data-connector='first-gate']").click_button("×")
      assert_no_selector "[data-connector='first-gate']"

      click_button("↶ Undo")

      assert_selector "[data-connector='first-gate']"
    end

    test "redoing takes away again the connection undoing put back" do
      canvas_for(flow)
      find("[data-connector='first-gate']").hover
      find("[data-connector='first-gate']").click_button("×")
      click_button("↶ Undo")
      assert_selector "[data-connector='first-gate']"

      click_button("↷ Redo")

      assert_no_selector "[data-connector='first-gate']"
    end

    test "the flow's panel stays out of the way until it is opened" do
      canvas_for(flow)

      assert_no_selector "[data-builder-panel]"
    end

    test "opening the flow's panel shows what has changed" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-builder-panel]", text: "Nothing has changed."
    end

    test "the flow's panel closes again" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("[data-builder-panel]").click_button("×")

      assert_no_selector "[data-builder-panel]"
    end

    test "the flow's panel says which version it stands at" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-history]", text: "Version 1 · never published"
    end

    test "a version is created from the flow's panel" do
      canvas_for(flow)
      step_card("first").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      assert_selector "[data-create-version]", text: "Create version"
    end

    test "the flow's panel links to the definition" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-definition]", text: "Definition"
    end

    test "the flow's panel links to the details" do
      canvas_for(flow)

      find("[data-open-panel]").click

      assert_selector "[data-details]", text: "Edit details"
    end

    test "the panel lists a change once a step is edited" do
      canvas_for(flow)
      step_card("first").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      assert_selector "[data-change]", text: "Updated"
    end

    test "the panel names a step that cannot be reached" do
      canvas_for(adrift)

      find("[data-open-panel]").click

      assert_selector "[data-problem]", text: "unreachable"
    end

    test "creating a version empties the change list" do
      canvas_for(wired)
      step_card("first").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click
      find("[data-create-version]").click

      assert_selector "[data-builder-panel]", text: "Nothing has changed."
    end

    test "publishing a flow with a problem is refused" do
      canvas_for(adrift)
      find("[data-open-panel]").click

      find("[data-publish]").click

      assert_selector "[data-refusal]"
    end

    test "the flow's panel says when there was nothing to capture" do
      canvas_for(wired)
      find("[data-open-panel]").click

      find("[data-create-version]").click

      assert_selector "[data-notice]", text: "Nothing has changed"
    end

    test "the flow's panel says which version it created" do
      canvas_for(wired)
      step_card("first").click
      fill_in_first_field_with("Changed by hand")
      find("[data-open-panel]").click

      find("[data-create-version]").click

      assert_selector "[data-notice]", text: "Created version 2."
    end

    test "the flow's panel closes when the canvas is clicked" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("body").click

      assert_no_selector "[data-builder-panel]"
    end

    test "the flow's standing leads to its history" do
      canvas_for(flow)
      find("[data-open-panel]").click

      find("[data-history]").click

      assert_selector "[data-version]", text: "Version 1"
    end

    test "the flow is renamed from its panel" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "[data-flow-name]", text: "A better name"
    end

    test "the flow's panel says the details were saved" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "[data-notice]", text: "Saved the flow's details."
    end

    test "the builder page follows the flow's new name" do
      canvas_for(flow)
      find("[data-open-panel]").click

      rename_to("A better name")

      assert_selector "header h1", text: "A better name"
    end

    test "saving one detail keeps the ones that were already stored" do
      named = flow.tap { |built| built.update!(start_label: "Begin") }
      canvas_for(named)
      find("[data-open-panel]").click

      rename_to("A better name")
      assert_selector "[data-notice]"

      assert_equal "Begin", named.reload.start_label
    end

    private

    def rename_to(name)
      find("[data-flow-title]").set(name)
      find("[data-builder-panel] h2", match: :first).click
    end

    def fill_in_first_field_with(text)
      field = find("[data-inspector] input[type='text']", match: :first)
      field.set(text)
      find("body").click
    end
  end
end
