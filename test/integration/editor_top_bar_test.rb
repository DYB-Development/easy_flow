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
  end
end
