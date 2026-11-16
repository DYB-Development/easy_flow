require "test_helper"

module EasyFlow
  class RunViewHelperTest < ActionView::TestCase
    helper RunViewHelper

    def version
      Definition.create!(host: "dummy", slug: "run-view-helper").record_definition(flowing(
        "entry" => "outline", "nodes" => [ { "id" => "outline", "type" => "question", "question" => "Outline", "answers" => [ { "value" => "on" } ] } ]
      ))
    end

    test "draws the run view of a flow version with the states its host supplied" do
      @version = version
      render inline: %(<%= easy_flow_run_view(@version, steps: { "outline" => { state: :paused } }) %>)

      assert_select "[data-react-ui='easy_flow/run-view'][data-props*='paused']"
    end
  end
end
