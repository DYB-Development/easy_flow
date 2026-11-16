require "test_helper"

module EasyFlow
  class EditorTopBarTest < ActionDispatch::IntegrationTest
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "top-bar").tap do |built|
        built.record_definition(flowing("slug" => "top-bar", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "answers" => [ { "value" => "yes" } ] } ],
          "edges" => []))
      end
    end

    test "the editor's top bar shows the version the draft is based on and its changes since" do
      get easy_flow.manage_flow_path(flow)

      assert_select "header [data-version-status]", text: "draft from v1 · unsaved 0 changes"
    end

    test "the canvas carries the draft status the top bar shows" do
      get "#{easy_flow.manage_flow_canvas_path(flow)}.json"

      assert_equal "draft from v1 · unsaved 0 changes", response.parsed_body["flow"]["status"]
    end

    test "the editor's top bar switches to the definition text" do
      get easy_flow.manage_flow_path(flow)

      assert_select "header [data-view-switch] a[href=?]", easy_flow.edit_manage_flow_definition_path(flow), text: "Text"
    end

    test "the definition text's top bar switches back to the canvas" do
      get easy_flow.edit_manage_flow_definition_path(flow)

      assert_select "header [data-view-switch] a[href=?]", easy_flow.manage_flow_path(flow), text: "Canvas"
    end

    test "the editor's top bar names the version Publish will create" do
      patch "#{easy_flow.manage_flow_canvas_path(flow)}/steps/a", params: { config: { question: "New", answers: [ { "value" => "yes" } ] } }

      get easy_flow.manage_flow_path(flow)

      assert_select "header button[data-bar-action=publish]", text: "Publish v2"
    end

    test "the editor's top bar shows the buttons its host adds" do
      EasyFlow.host_named("dummy").editor_buttons = ->(shown) { [ { label: "Run tests", address: "/tests/#{shown.slug}" } ] }

      get easy_flow.manage_flow_path(flow)

      assert_select "header a[href=?]", "/tests/top-bar", text: "Run tests"
    ensure
      EasyFlow.host_named("dummy").editor_buttons = nil
    end
  end
end
