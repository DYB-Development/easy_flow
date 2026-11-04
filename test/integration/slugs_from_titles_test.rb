require "test_helper"

module EasyFlow
  class SlugsFromTitlesTest < ActionDispatch::IntegrationTest
    setup { EasyFlow.host_named(:dummy).slugs_from_titles = true }
    teardown { EasyFlow.host_named(:dummy).slugs_from_titles = false }

    test "the new flow page does not ask for a slug" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[slug]", count: 0
    end

    test "the new flow page asks for a title" do
      get easy_flow.new_manage_flow_path

      assert_select "input[name=?]", "flow[title]"
    end
  end
end
