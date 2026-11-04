require "test_helper"

module EasyFlow
  class NewFlowPageTest < ActionDispatch::IntegrationTest
    teardown { EasyFlow.host_named(:dummy).new_flow_kind = nil }

    test "the new flow page shows the form that creates a flow" do
      get easy_flow.new_manage_flow_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end

    test "the new flow page asks for a title" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[title]"
    end

    test "a flow created from the page has the title typed" do
      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "guide" } }

      assert Definition.exists?(host: "dummy", title: "Morning Routine")
    end

    test "the new flow page does not ask for a slug" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[slug]", count: 0
    end

    test "a flow created from the page has a slug made from the title typed" do
      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "guide" } }

      assert_equal "morning-routine", Definition.find_by!(host: "dummy", title: "Morning Routine").slug
    end

    test "a second flow created from the page with the same title takes a different slug" do
      2.times { post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "guide" } } }

      assert_equal %w[morning-routine morning-routine-2], Definition.where(host: "dummy", title: "Morning Routine").order(:id).pluck(:slug)
    end

    test "a blank title on the page says the title cannot be blank" do
      post easy_flow.manage_flows_path, params: { flow: { title: "" } }

      assert_select "*", text: /Title can.t be blank/
    end

    test "the new flow page does not ask for a kind when the host has set one" do
      EasyFlow.host_named(:dummy).new_flow_kind = :guide

      get easy_flow.new_manage_flow_path

      assert_select "select[name=?]", "flow[kind]", count: 0
    end

    test "a flow created from the page has the kind the host set, whatever is posted" do
      EasyFlow.host_named(:dummy).new_flow_kind = :guide

      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "scored" } }

      assert_equal "guide", Definition.find_by!(host: "dummy", title: "Morning Routine").kind
    end

    test "the flow list links to the new flow page" do
      get easy_flow.manage_flows_path

      assert_select "a[href=?]", easy_flow.new_manage_flow_path
    end

    test "the flow list has no form that creates a flow" do
      get easy_flow.manage_flows_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path, count: 0
    end

    test "a flow that cannot be created is shown again on the new flow page" do
      post easy_flow.manage_flows_path, params: { flow: { title: "", kind: "guide" } }

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end
  end
end
