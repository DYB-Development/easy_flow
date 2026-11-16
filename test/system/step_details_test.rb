require "application_system_test_case"

module EasyFlow
  class StepDetailsTest < ApplicationSystemTestCase
    def agent_flow
      @agent_flow ||= Definition.create!(host: "dummy", slug: "step-details").tap do |built|
        built.record_definition(flowing(
          "slug" => "step-details", "entry" => "write_variant",
          "nodes" => [ { "id" => "write_variant", "type" => "agent", "agent" => "copy_writer", "alias" => "prod" },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "write_variant", "to" => "end" } ]
        ))
      end
    end

    def open_agent_settings
      canvas_for(agent_flow)
      step_card("write_variant").click
      assert_selector "[data-inspector]"
    end

    test "opening an agent step shows which earlier output feeds each of its inputs" do
      open_agent_settings

      assert_selector "[data-inspector] .ks-value-list", text: "brief\nload_brief.out.brief"
    end
  end
end
