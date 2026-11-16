require "application_system_test_case"

module EasyFlow
  class EditorTopBarTest < ApplicationSystemTestCase
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "top-bar-system").tap do |built|
        built.record_definition(flowing(
          "slug" => "top-bar-system", "entry" => "first",
          "nodes" => [ { "id" => "first", "type" => "question", "question" => "First", "answers" => [ { "value" => "yes" } ] },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "first", "to" => "end" } ]
        ))
      end
    end

    def change_the_first_step
      step_card("first").click
      find("[data-inspector] input[type='text']", match: :first).set("Changed by hand")
      find("body").click
    end

    test "the top bar counts a change made on the canvas" do
      canvas_for(flow)
      change_the_first_step

      assert_selector "[data-version-status]", text: "draft from v1 · unsaved 1 change"
    end

    test "pressing Publish in the top bar publishes the draft" do
      canvas_for(flow)
      change_the_first_step

      find("[data-bar-action=publish]").click

      assert_selector "[data-notice]", text: "Published version 2."
    end

    test "pressing Save draft in the top bar makes a version from the draft" do
      canvas_for(flow)
      change_the_first_step

      find("[data-bar-action=save_draft]").click

      assert_selector "[data-notice]", text: "Created version 2."
    end

    test "the top bar's Publish names the next version once the canvas changes" do
      canvas_for(flow)
      change_the_first_step

      assert_selector "[data-bar-action=publish]", text: "Publish v2"
    end
  end
end
