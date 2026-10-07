require "test_helper"

module EasyFlow
  class DefinitionEditorTest < ActionDispatch::IntegrationTest
    test "a branching definition saved in the builder runs in the stepper" do
      flow = Definition.create!(host: "dummy", slug: "flow")
      flow.record_definition("slug" => "flow")

      patch easy_flow.manage_flow_definition_path(flow), params: { definition: flowing({
        "slug" => "flow", "entry" => "path",
        "nodes" => [
          { "id" => "path", "type" => "question", "text" => "Which path?", "options" => [ "left", "right" ] },
          { "id" => "gate", "type" => "condition", "step" => "path", "output" => "answer", "comparison" => "is", "answer" => "right" },
          { "id" => "left_q", "type" => "question", "text" => "Left question", "options" => [ "x" ] },
          { "id" => "right_q", "type" => "question", "text" => "Right question", "options" => [ "y" ] }
        ],
        "edges" => [
          { "from" => "path", "to" => "gate" },
          { "from" => "gate", "to" => "right_q", "on" => true },
          { "from" => "gate", "to" => "left_q", "on" => false }
        ]
      }).to_json }

      flow.reload.publish

      get easy_flow.flow_step_path("flow"), params: { answers: { path: "right" } }

      assert_select "legend", text: /Right question/
    end

    test "the definition editor shows the current definition" do
      flow = Definition.create!(host: "dummy", slug: "doc")
      flow.record_definition("slug" => "doc", "questions" => [ { "id" => "need", "text" => "Need?" } ])

      get easy_flow.edit_manage_flow_definition_path(flow)

      assert_select "textarea", text: /"id": "need"/
    end

    test "the editor shows the flow being edited, not the last version cut" do
      fresh = Definition.create!(host: "dummy", slug: "fresh")

      get easy_flow.edit_manage_flow_definition_path(fresh)

      assert_select "textarea", text: /"type": "start"/
    end

    test "editing the definition changes the flow without cutting a version" do
      fresh = Definition.create!(host: "dummy", slug: "fresh-edit")
      edited = fresh.document.merge("headline" => "Edited by hand")

      assert_no_difference -> { fresh.definition_versions.count } do
        patch easy_flow.manage_flow_definition_path(fresh), params: { definition: edited.to_json }
      end

      assert_equal "Edited by hand", fresh.reload.document["headline"]
    end

    test "editing the definition records that it changed" do
      fresh = Definition.create!(host: "dummy", slug: "fresh-change")

      patch easy_flow.manage_flow_definition_path(fresh), params: { definition: fresh.document.to_json }

      assert_equal "edited", fresh.reload.changes_since_version.last["action"]
    end

    test "removing a flow a waiting parent run depends on is refused with a message naming the parent flow" do
      inner = Definition.create!(host: "dummy", slug: "inner-offer").tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: flowing("slug" => "inner-offer", "entry" => "ask",
          "nodes" => [ { "id" => "ask", "type" => "question", "text" => "Buy?", "options" => [ "yes" ] } ], "edges" => [])))
      end
      parent = Definition.create!(host: "dummy", slug: "stack", title: "Stack").tap do |flow|
        flow.publish_version(flow.definition_versions.create!(number: 1, definition: flowing("slug" => "stack", "entry" => "offer",
          "nodes" => [ { "id" => "offer", "type" => "flow_step", "flow" => inner.id.to_s, "version" => 1 } ], "edges" => [])))
      end
      Run.start(parent).advance

      delete easy_flow.manage_flow_path(inner)

      assert_equal "This flow cannot be removed while Stack waits on one of its runs", flash[:alert]
    end
  end
end
