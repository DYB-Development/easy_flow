require "test_helper"

module EasyFlow
  class SlugsFromTitlesTest < ActionDispatch::IntegrationTest
    setup { EasyFlow.host_named(:dummy).slugs_from_titles = true }
    teardown { EasyFlow.host_named(:dummy).slugs_from_titles = false }
    teardown { EasyFlow.host_named(:owned).slugs_from_titles = false }

    test "the new flow page does not ask for a slug" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[slug]", count: 0
    end

    test "the new flow page asks for a title" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[title]"
    end

    test "a flow created from the page has the title typed" do
      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", kind: "guide" } }

      assert Definition.exists?(host: "dummy", title: "Morning Routine")
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

    test "a second flow created for the same owner with the same title takes a different slug" do
      owner = Customer.create!(name: "Ours")
      EasyFlow.host_named(:owned).slugs_from_titles = true

      2.times { post "/owned/manage/flows", params: { flow: { title: "Fresh" } }, headers: { "X-Customer" => owner.id.to_s } }

      assert_equal %w[fresh fresh-2], Definition.where(host: "owned", owner: owner).order(:id).pluck(:slug)
    end

    test "a slug posted to the page is ignored" do
      post easy_flow.manage_flows_path, params: { flow: { title: "Morning Routine", slug: "typed-by-hand", kind: "guide" } }

      assert_equal "morning-routine", Definition.find_by!(host: "dummy", title: "Morning Routine").slug
    end

    test "the new flow page still asks for a kind" do
      get easy_flow.new_manage_flow_path

      assert_select "select[name=?]", "flow[kind]"
    end
  end
end
