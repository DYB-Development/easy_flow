require "test_helper"

module EasyFlow
  class NewFlowPageTest < ActionDispatch::IntegrationTest
    test "the new flow page shows the form that creates a flow" do
      get easy_flow.new_manage_flow_path

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
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
      post easy_flow.manage_flows_path, params: { flow: { slug: "" } }

      assert_select "form[action=?][method=post]", easy_flow.manage_flows_path
    end

    test "a flow created on the new flow page can be published and run" do
      post easy_flow.manage_flows_path, params: { flow: { slug: "from-the-page" } }
      flow = Definition.find_by!(slug: "from-the-page")
      flow.update!(persists: :each_step)
      flow.publish_version(flow.definition_versions.create!(number: 1, definition: flowing("slug" => "from-the-page", "entry" => "ask",
        "nodes" => [ { "id" => "ask", "type" => "question", "text" => "Ready?", "options" => [ "yes" ] }, { "id" => "done", "type" => "terminal" } ],
        "edges" => [ { "from" => "ask", "to" => "done" } ])))

      post easy_flow.flow_runs_path(flow.slug)
      patch easy_flow.run_path(flow.runs.last), params: { answers: { ask: "yes" } }

      assert_equal "yes", flow.runs.last.recorded[:ask]
    end
  end
end
