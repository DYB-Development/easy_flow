require "test_helper"

module EasyFlow
  class HostManagementTest < ActionDispatch::IntegrationTest
    def console_flow
      @console_flow ||= Definition.create!(host: "console", slug: "console-setup", title: "Console setup")
    end

    test "a host's flow list leaves out another host's flows" do
      console_flow

      get easy_flow.manage_flows_path

      assert_select "a", text: "Console setup", count: 0
    end

    test "a flow created on a host's management pages belongs to that host" do
      post easy_flow.manage_flows_path, params: { flow: { slug: "made-here", kind: "guide" } }

      assert_equal "dummy", Definition.find_by!(slug: "made-here").host
    end

    test "a host's pages do not show another host's flow" do
      get easy_flow.manage_flow_path(console_flow)

      assert_response :not_found
    end

    test "a host's pages do not open another host's flow for editing" do
      get easy_flow.edit_manage_flow_path(console_flow)

      assert_response :not_found
    end

    test "a host's pages do not save changes to another host's flow" do
      patch easy_flow.manage_flow_path(console_flow), params: { flow: { title: "Taken over" } }

      assert_response :not_found
    end

    test "a host's pages do not remove another host's flow" do
      delete easy_flow.manage_flow_path(console_flow)

      assert Definition.exists?(console_flow.id)
    end

    test "a host's definition editor does not open another host's flow" do
      get easy_flow.edit_manage_flow_definition_path(console_flow)

      assert_response :not_found
    end

    test "a host's definition editor does not save into another host's flow" do
      patch easy_flow.manage_flow_definition_path(console_flow), params: { definition: { "headline" => "Taken over" }.to_json }

      assert_response :not_found
    end

    test "a host's pages do not list another host's versions" do
      get easy_flow.manage_flow_versions_path(console_flow)

      assert_response :not_found
    end

    test "a host's canvas does not draw another host's flow" do
      get easy_flow.manage_flow_canvas_path(console_flow)

      assert_response :not_found
    end

    test "a host's pages do not preview another host's flow" do
      get easy_flow.manage_flow_preview_path(console_flow)

      assert_response :not_found
    end
  end
end
