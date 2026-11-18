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

    def branching_version
      Definition.create!(host: "dummy", slug: "branching").record_definition(flowing(
        "entry" => "review",
        "nodes" => [ { "id" => "review", "type" => "question", "question" => "Review", "answers" => [ { "value" => "yes" }, { "value" => "no" } ] },
                     { "id" => "gate", "type" => "condition", "step" => "review", "output" => "answer", "comparison" => "is", "answer" => "yes" },
                     { "id" => "publish_to_cms", "type" => "question", "question" => "Publish to CMS", "answers" => [ { "value" => "on" } ] },
                     { "id" => "published", "type" => "terminal" },
                     { "id" => "rejected", "type" => "terminal" } ],
        "edges" => [ { "from" => "review", "to" => "gate" }, { "from" => "gate", "to" => "publish_to_cms", "on" => true },
                     { "from" => "gate", "to" => "rejected", "on" => false }, { "from" => "publish_to_cms", "to" => "published" } ]
      ))
    end

    test "a run view shows the End step its run ended at as reached" do
      visit "/runs/#{branching_version.id}?ended_at=rejected"

      assert_selector "[data-flow-run-view] [data-step='rejected'].border-green-600"
    end

    test "a host page shows the run view of a flow version with each step's state" do
      visit "/runs/#{run_version.id}"

      assert_selector "[data-flow-run-view] [data-step='human_approve']", text: "waiting · expires 46h"
    end

    test "a run view draws each connection between its steps as a line" do
      visit "/runs/#{run_version.id}"

      assert_selector "[data-flow-run-view] path[data-link^='human_approve-publish_to_cms']", visible: :all
    end

    test "a run view draws the Start step and the line from it to the first step" do
      visit "/runs/#{run_version.id}"

      assert_selector "[data-flow-run-view] path[data-link^='start-load_brief']", visible: :all
    end

    test "a run view draws the line into each End step with its branch label" do
      visit "/runs/#{branching_version.id}"

      assert_selector "[data-flow-run-view] [data-link-label^='gate-rejected']", text: "false"
    end

    test "a run view draws the Start and End cards as cards that link nowhere, even when its host gives them an address" do
      visit "/runs/#{branching_version.id}"
      find("[data-flow-run-view] a[data-step='review']")

      assert_no_selector "[data-flow-run-view] a[data-step='start'], [data-flow-run-view] a[data-step='rejected']"
    end

    def on_a_phone
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true)
      yield
    ensure
      page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    end

    def card_edges(*ids)
      ids.map { |id| page.evaluate_script(%((() => { const card = document.querySelector("[data-step='#{id}']").getBoundingClientRect(); return [ Math.round(card.left), card.right <= window.innerWidth ] })())) }
    end

    test "on a phone, the run view stacks its cards one per row within the width of the page" do
      on_a_phone do
        visit "/runs/#{run_version.id}"
        find("[data-step='human_approve']")

        assert_equal [ [ 16, true ] ] * 3, card_edges("load_brief", "outline", "human_approve")
      end
    end
  end
end
