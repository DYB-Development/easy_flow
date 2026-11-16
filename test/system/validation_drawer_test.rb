require "application_system_test_case"

module EasyFlow
  class ValidationDrawerTest < ApplicationSystemTestCase
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "validation-drawer").tap do |built|
        built.record_definition(flowing(
          "slug" => "validation-drawer", "entry" => "publish_to_cms",
          "nodes" => [ { "id" => "publish_to_cms", "type" => "integration", "effect" => "keyed" },
                       { "id" => "ab_test_created", "type" => "emit_event" },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "publish_to_cms", "to" => "ab_test_created" }, { "from" => "ab_test_created", "to" => "end" } ]
        ))
      end
    end

    test "the drawer under the canvas lists a flow's problem with the step it is on" do
      canvas_for(flow)

      assert_selector "[data-drawer] [data-check-row]", text: "error\nab_test_created"
    end
  end
end
