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

    test "clicking a schema's line on an agent step shows its code" do
      open_agent_settings

      find("[data-inspector] summary", text: "input_schema").click

      assert_selector "[data-inspector] .ks-code-block", text: "{brief: Brief, voice: string, angle: string, findings?: Finding[]}"
    end

    def open_the_output_schema
      open_agent_settings
      find("[data-inspector] summary", text: "output_schema").click
      assert_selector "[data-inspector] .ks-code-block", text: "headline"
    end

    def width_of(selector)
      page.evaluate_script(%(document.querySelector("#{selector}").getBoundingClientRect().width))
    end

    test "opening a schema wider than the settings panel leaves the panel 320 pixels wide" do
      open_the_output_schema

      assert_equal 320, width_of("[data-inspector]")
    end
  end
end
