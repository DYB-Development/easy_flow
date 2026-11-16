require "application_system_test_case"

module EasyFlow
  class RunViewTest < ApplicationSystemTestCase
    def run_version
      Definition.create!(host: "dummy", slug: "pipeline").record_definition(flowing(
        "entry" => "load_brief",
        "nodes" => [ { "id" => "load_brief", "type" => "question", "question" => "Load brief", "answers" => [ { "value" => "on" } ] },
                     { "id" => "outline", "type" => "question", "question" => "Outline", "answers" => [ { "value" => "on" } ] },
                     { "id" => "variants", "type" => "for_each", "list" => "outline.variants", "concurrency" => 3,
                       "holds" => [ "write_variant", "length_terms_claims" ] },
                     { "id" => "write_variant", "type" => "question", "question" => "Write variant", "answers" => [ { "value" => "on" } ] },
                     { "id" => "length_terms_claims", "type" => "question", "question" => "Length, terms and claims", "answers" => [ { "value" => "on" } ] },
                     { "id" => "human_approve", "type" => "question", "question" => "Human approve", "answers" => [ { "value" => "on" } ] },
                     { "id" => "publish_to_cms", "type" => "question", "question" => "Publish to CMS", "answers" => [ { "value" => "on" } ] },
                     { "id" => "end", "type" => "terminal" } ],
        "edges" => [ { "from" => "load_brief", "to" => "outline" }, { "from" => "outline", "to" => "variants" },
                     { "from" => "variants", "to" => "write_variant" }, { "from" => "write_variant", "to" => "length_terms_claims" },
                     { "from" => "length_terms_claims", "to" => "human_approve" }, { "from" => "human_approve", "to" => "publish_to_cms" },
                     { "from" => "publish_to_cms", "to" => "end" } ]
      ))
    end

    test "a host page shows the run view of a flow version with each step's state" do
      visit "/runs/#{run_version.id}"

      assert_selector "[data-flow-run-view] [data-step='human_approve']", text: "waiting · expires 46h"
    end
  end
end
