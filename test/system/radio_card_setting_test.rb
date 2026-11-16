require "application_system_test_case"

module EasyFlow
  class RadioCardSettingTest < ApplicationSystemTestCase
    def agent_flow
      @agent_flow ||= Definition.create!(host: "dummy", slug: "radio-card-setting").tap do |built|
        built.record_definition(flowing(
          "slug" => "radio-card-setting", "entry" => "write_variant",
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

    test "opening an agent step shows each alias choice as a radio card with its hint" do
      open_agent_settings

      assert_selector "[data-inspector] .ks-radio-card", text: "candidate → v23\np 0.87 · n 240"
    end
  end
end
