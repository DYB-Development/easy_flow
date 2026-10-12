require "test_helper"
require "public_code/test_help"

module EasyFlow
  class FlowCodesTest < ActionDispatch::IntegrationTest
    include PublicCode::TestHelp

    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "coded", title: "Coded").tap do |made|
        2.times do |time|
          made.record_definition(flowing("slug" => "coded", "entry" => "a", "nodes" => [ { "id" => "a", "type" => "question", "text" => "A #{time}", "options" => [ "x" ] } ], "edges" => []))
          made.publish
        end
      end
    end

    test "a flow's management pages link to no numbered address where the app has flow codes" do
      pages = [
        easy_flow.manage_flows_path,
        easy_flow.manage_flow_path(flow),
        easy_flow.edit_manage_flow_path(flow),
        easy_flow.edit_manage_flow_definition_path(flow),
        easy_flow.manage_flow_canvas_path(flow),
        easy_flow.manage_flow_preview_path(flow),
        easy_flow.manage_flow_versions_path(flow)
      ]

      assert_no_numbered_links(pages)
    end
  end
end
