require "test_helper"

module EasyFlow
  class CanvasBuilderTest < ActionDispatch::IntegrationTest
    def flow
      @flow ||= Definition.create!(host: "dummy", slug: "canvas").tap do |built|
        built.record_definition(flowing(
          "slug" => "canvas", "entry" => "a",
          "nodes" => [ { "id" => "a", "type" => "question", "text" => "A", "answers" => [ { "value" => "yes" } ] },
                       { "id" => "b", "type" => "question", "answers" => [ { "value" => "yes" } ] },
                       { "id" => "end", "type" => "terminal" } ],
          "edges" => [ { "from" => "a", "to" => "b" }, { "from" => "b", "to" => "end" } ]
        ))
      end
    end

    def canvas_path
      easy_flow.manage_flow_canvas_path(flow)
    end

    def add_step_with_answers(id, from: nil, to: nil)
      post "#{canvas_path}/steps", params: { id: id, type: "question", from: from, to: to }.compact
      patch "#{canvas_path}/steps/#{id}", params: { config: { question: "New", answers: [ { "value" => "yes" } ] } }
    end

    def nodes
      flow.reload.document["nodes"].map { |node| node["id"] }
    end

    test "the flow page mounts the flow canvas" do
      get easy_flow.manage_flow_path(flow)

      assert_select "[data-flow-canvas]"
    end

    test "the flow page renders the flow editor through the React UI helper" do
      get easy_flow.manage_flow_path(flow)

      assert_select "[data-flow-canvas][data-react-ui=?]", "easy_flow/flow-editor"
    end

    test "the flow editor's props point it at its edit endpoints" do
      get easy_flow.manage_flow_path(flow)

      assert_equal canvas_path, JSON.parse(css_select("[data-react-ui]").first["data-props"])["base"]
    end

    test "the canvas screen carries the flow as JSON" do
      get "#{canvas_path}.json"

      assert_equal [ "start", "a", "b", "end" ], response.parsed_body["nodes"].map { |node| node["id"] }
    end

    test "the canvas screen carries the registered step types as a palette" do
      get "#{canvas_path}.json"

      assert_includes response.parsed_body["palette"].map { |entry| entry["type"] }, "question"
    end

    test "adding a step records a new version carrying it" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal [ "start", "a", "b", "end", "c" ], nodes
    end

    test "undoing an edit restores what the flow was before it" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      post "#{canvas_path}/undo"

      assert_equal [ "start", "a", "b", "end" ], nodes
    end

    test "redoing puts back what was undone" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/undo"

      post "#{canvas_path}/redo"

      assert_equal [ "start", "a", "b", "end", "c" ], nodes
    end

    test "the canvas says whether there is anything to redo" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/undo"

      get "#{canvas_path}.json"

      assert response.parsed_body["redoable"]
    end

    test "undoing with nothing behind it leaves the flow alone" do
      post "#{canvas_path}/undo"

      assert_equal [ "start", "a", "b", "end" ], nodes
    end

    test "the canvas says whether there is anything to undo" do
      get "#{canvas_path}.json"

      assert_not response.parsed_body["undoable"]
    end

    test "the canvas says there is something to undo after an edit" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get "#{canvas_path}.json"

      assert response.parsed_body["undoable"]
    end

    test "adding a step from a port connects it to that branch" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "b", on: "no" }

      assert_includes flow.reload.document["edges"], { "from" => "b", "to" => "c", "on" => "no" }
    end

    test "adding a step from a port leaves the other branches alone" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "b", on: "no" }

      assert_includes flow.reload.document["edges"].map { |edge| edge["to"] }, "b"
    end

    test "adding a step on an edge puts it between the two steps" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question", from: "a", to: "b" }

      assert_equal [ [ "start", "a" ], [ "b", "end" ], [ "a", "c" ], [ "c", "b" ] ],
        flow.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    test "configuring a step records the new configuration" do
      patch "#{canvas_path}/steps/a", params: { config: { text: "Changed" } }

      assert_equal "Changed", flow.reload.document["nodes"].find { |node| node["id"] == "a" }["text"]
    end

    test "removing a step records a version without it" do
      delete "#{canvas_path}/steps/b"

      assert_equal [ "start", "a", "end" ], nodes
    end

    test "connecting two steps records the new edge" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "b", to: "c" }

      assert_includes flow.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }, [ "b", "c" ]
    end

    test "disconnecting two steps records a version without the edge" do
      delete "#{canvas_path}/edges", params: { from: "a", to: "b" }

      assert_equal [ [ "start", "a" ], [ "b", "end" ] ],
        flow.reload.document["edges"].map { |edge| [ edge["from"], edge["to"] ] }
    end

    test "editing records no new version" do
      assert_no_difference -> { flow.definition_versions.count } do
        post "#{canvas_path}/steps", params: { id: "c", type: "question" }
        patch "#{canvas_path}/steps/a", params: { config: { question: "Changed" } }
        post "#{canvas_path}/edges", params: { from: "a", to: "c" }
        delete "#{canvas_path}/steps/c"
      end
    end

    test "a refused edit leaves the definition untouched" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_equal [ "start", "a", "b", "end" ], nodes
    end

    test "a refused edit reports why" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_response :unprocessable_entity
    end

    test "configuring a step stores a number for a setting declared as one" do
      patch "#{canvas_path}/steps/a", params: { config: { answers: [ { value: "low", weight: "4" } ] } }

      stored = flow.reload.document["nodes"].find { |node| node["id"] == "a" }

      assert_equal 4, stored["answers"].first["weight"]
    end

    test "configuring a step refuses more choices than the setting allows" do
      post "#{canvas_path}/steps", params: { id: "n", type: "notify" }
      before = flow.reload.definition_cursor

      patch "#{canvas_path}/steps/n", params: { config: { channels: %w[email sms push] } }

      assert_equal before, flow.reload.definition_cursor
    end

    test "adding a step writes it into the live document" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_includes flow.reload.document["nodes"].map { |node| node["id"] }, "c"
    end

    test "the builder renders the document being edited, not the recorded version" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get easy_flow.manage_flow_path(flow)

      drawn = JSON.parse(css_select("[data-flow-canvas]").first["data-props"])["initial"]

      assert_includes drawn["nodes"].map { |node| node["id"] }, "c"
    end

    test "creating a version records the document being edited" do
      add_step_with_answers("c", from: "b", to: "end")

      assert_difference -> { flow.definition_versions.count } do
        post "#{canvas_path}/versions"
      end
    end

    test "adding a step records what changed" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal "added", flow.reload.changes_since_version.last["action"]
    end

    test "a change names the step it touched" do
      patch "#{canvas_path}/steps/a", params: { config: { question: "What is your budget?" } }

      assert_equal [ "What is your budget?" ], flow.reload.changes_since_version.last["named"]
    end

    test "a change falls back to the step id when it has no name" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      assert_equal [ "c" ], flow.reload.changes_since_version.last["named"]
    end

    test "changes accumulate in the order the edits happened" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }
      post "#{canvas_path}/edges", params: { from: "a", to: "c" }

      assert_equal %w[added connected], flow.reload.changes_since_version.map { |change| change["action"] }
    end

    test "a refused edit records nothing" do
      post "#{canvas_path}/steps", params: { id: "a", type: "question" }

      assert_empty flow.reload.changes_since_version.to_a
    end

    test "publishing refuses a document with problems" do
      post "#{canvas_path}/steps", params: { id: "adrift", type: "question" }

      post "#{canvas_path}/publish"

      assert_response :unprocessable_entity
      assert_nil flow.reload.live_version
    end

    test "publishing a sound document marks it for visitors" do
      post "#{canvas_path}/publish"

      assert_equal flow.reload.definition_versions.last, flow.live_version
    end

    test "the canvas carries what has changed since the last version" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal [ "Added “c”" ], response.parsed_body["changes"]
    end

    test "the canvas ships a change as a sentence, not the document undo keeps" do
      post "#{canvas_path}/steps", params: { id: "c", type: "question" }

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_kind_of String, response.parsed_body["changes"].first
    end

    test "the change list empties when a version is created" do
      add_step_with_answers("c", from: "b", to: "end")
      post "#{canvas_path}/versions"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_empty response.parsed_body["changes"]
    end

    test "the canvas carries which version this flow stands at" do
      post "#{canvas_path}/versions"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal flow.reload.current_definition_version.number, response.parsed_body["flow"]["version"]
    end

    test "the canvas carries which version visitors run" do
      post "#{canvas_path}/publish"

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal flow.reload.live_version.number, response.parsed_body["flow"]["published"]
    end

    test "the canvas carries where the definition is edited" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal easy_flow.edit_manage_flow_definition_path(flow), response.parsed_body["flow"]["definition_url"]
    end

    test "the canvas carries where the details are edited" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal easy_flow.edit_manage_flow_path(flow), response.parsed_body["flow"]["details_url"]
    end

    test "saving the details stores the flow's title" do
      patch "#{canvas_path}/details", params: { flow: { title: "A better name" } }

      assert_equal "A better name", flow.reload.title
    end

    test "saving the details stores what the flow keeps of a run" do
      patch "#{canvas_path}/details", params: { flow: { persists: "each_step" } }

      assert_predicate flow.reload, :each_step?
    end

    test "saving the details says they were saved" do
      patch "#{canvas_path}/details", params: { flow: { title: "A better name" } }

      assert_equal "Saved the flow's details.", response.parsed_body["notice"]
    end

    test "the canvas carries the flow's start label" do
      flow.update!(start_label: "Begin")

      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal "Begin", response.parsed_body["flow"]["start_label"]
    end

    test "the canvas carries the flow's slug" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_equal "canvas", response.parsed_body["flow"]["slug"]
    end

    test "the canvas carries the title of a flow that has none as nothing" do
      get canvas_path, headers: { "Accept" => "application/json" }

      assert_nil response.parsed_body["flow"]["title"]
    end

    test "a refused publish says it could not publish and why" do
      post "#{canvas_path}/steps", params: { id: "adrift", type: "question" }

      post "#{canvas_path}/publish"

      assert_equal "Cannot publish: “adrift” is unreachable, “adrift” is missing setting, “adrift” is dead end.",
        response.parsed_body["error"]
    end

    test "creating a version says which one it created" do
      add_step_with_answers("c", from: "b", to: "end")

      post "#{canvas_path}/versions"

      assert_equal "Created version 2.", response.parsed_body["notice"]
    end

    test "creating a version says when there was nothing to capture" do
      post "#{canvas_path}/versions"

      assert_equal "Nothing has changed since version 1.", response.parsed_body["notice"]
    end

    test "publishing says which version visitors now run" do
      add_step_with_answers("c", from: "b", to: "end")

      post "#{canvas_path}/publish"

      assert_equal "Published version 2. Visitors run it now.", response.parsed_body["notice"]
    end

    test "publishing says when visitors already run this version" do
      post "#{canvas_path}/publish"

      post "#{canvas_path}/publish"

      assert_equal "Visitors already run version 1.", response.parsed_body["notice"]
    end

    test "the versions page lists a flow's versions newest first" do
      add_step_with_answers("c", from: "b", to: "end")
      post "#{canvas_path}/versions"

      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-version]:first-of-type", text: /2/
    end

    test "the versions page marks the version visitors run" do
      post "#{canvas_path}/publish"

      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-live]"
    end

    test "the versions page shows what a version captured" do
      add_step_with_answers("c", from: "b", to: "end")
      post "#{canvas_path}/versions"

      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-captured]", text: /Added/
    end

    test "the versions page lists a version that captured nothing" do
      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-version]", count: 1
    end

    test "the history offers a way back to an earlier version" do
      add_step_with_answers("c", from: "b", to: "end")
      post "#{canvas_path}/versions"

      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-return]", count: 1
    end

    test "returning from the history makes that version the live document" do
      add_step_with_answers("c", from: "b", to: "end")
      post "#{canvas_path}/versions"
      first = flow.definition_versions.order(:number).first

      post easy_flow.return_manage_flow_version_path(flow, first)

      assert_equal first.definition, flow.reload.document
    end

    test "cutting a version is refused while the flow has a problem" do
      post "#{canvas_path}/steps", params: { id: "adrift", type: "question" }

      post "#{canvas_path}/versions"

      assert_response :unprocessable_entity
    end

    test "removing the step a flow begins at is refused" do
      delete "#{canvas_path}/steps/start"

      assert_response :unprocessable_entity
    end

    test "removing a step a flow ends at is allowed, since a flow may end in several places" do
      delete "#{canvas_path}/steps/end"

      assert_response :no_content
    end

    test "the builder page offers a way to try the flow as a visitor" do
      get easy_flow.manage_flow_path(flow)

      assert_select "a[href=?]", easy_flow.manage_flow_preview_path(flow)
    end

    test "the flow editor's props carry the flow it starts with" do
      get easy_flow.manage_flow_path(flow)
      initial = JSON.parse(css_select("[data-react-ui]").first["data-props"])["initial"]

      assert_equal %w[a b end], initial["nodes"].map { |node| node["id"] }.select { |id| %w[a b end].include?(id) }
    end

    test "the flow editor's props carry the token it sends with each edit" do
      get easy_flow.manage_flow_path(flow)

      assert_predicate JSON.parse(css_select("[data-react-ui]").first["data-props"])["token"], :present?
    end

    test "the canvas screen leaves out the step types its host does not offer" do
      EasyFlow.host_named(:dummy).offers = %i[compare]

      get "#{canvas_path}.json"

      assert_not_includes response.parsed_body["palette"].map { |entry| entry["type"] }, "question"
    ensure
      EasyFlow.host_named(:dummy).offers = nil
    end

    test "saving a step's settings writes a setting kept on a host record to that record" do
      customer = Customer.create!(name: "Dana")
      post "#{canvas_path}/steps", params: { id: "c", type: "name_customer" }

      patch "#{canvas_path}/steps/c", params: { config: { customer: customer.id.to_s, customer_name: "Dana Reyes" } }

      assert_equal "Dana Reyes", customer.reload.name
    end

    test "saving a step's settings leaves a setting kept on a host record out of the flow's document" do
      customer = Customer.create!(name: "Dana")
      post "#{canvas_path}/steps", params: { id: "c", type: "name_customer" }

      patch "#{canvas_path}/steps/c", params: { config: { customer: customer.id.to_s, customer_name: "Dana Reyes" } }

      assert_equal({ "id" => "c", "type" => "name_customer", "customer" => customer.id.to_s }, flow.reload.document["nodes"].find { |node| node["id"] == "c" })
    end

    test "a value the host record refuses is shown as an error on the setting and nothing is saved" do
      customer = Customer.create!(name: "Dana")
      post "#{canvas_path}/steps", params: { id: "c", type: "name_customer" }

      patch "#{canvas_path}/steps/c", params: { config: { customer: customer.id.to_s, customer_name: "D" * 41 } }

      assert_equal [ 422, "Customer name is too long (maximum is 40 characters)", "Dana", nil ],
        [ response.status, response.parsed_body["error"], customer.reload.name, flow.reload.document["nodes"].find { |node| node["id"] == "c" }["customer"] ]
    end

    test "a Flow step on the canvas is offered the flows on its own host and none on another" do
      parent = Definition.create!(host: "dummy", slug: "parent", title: "Parent").tap do |built|
        built.record_definition(flowing("slug" => "parent", "entry" => "inner", "nodes" => [ { "id" => "inner", "type" => "flow_step" } ], "edges" => []))
      end
      Definition.create!(host: "dummy", slug: "onboarding", title: "Onboarding")
      Definition.create!(host: "console", slug: "elsewhere", title: "Elsewhere")

      get "#{easy_flow.manage_flow_canvas_path(parent)}.json"

      offered = response.parsed_body["nodes"].find { |node| node["id"] == "inner" }["choices"]["flow"].map { |choice| choice["label"] }

      assert_equal %w[Onboarding], offered & %w[Onboarding Elsewhere]
    end

    test "a Flow step on the canvas leads to the canvas of the flow it runs, saying which flow it came from" do
      onboarding = Definition.create!(host: "dummy", slug: "onboarding", title: "Onboarding")
      parent = Definition.create!(host: "dummy", slug: "parent", title: "Parent").tap do |built|
        built.record_definition(flowing("slug" => "parent", "entry" => "inner", "nodes" => [ { "id" => "inner", "type" => "flow_step", "flow" => onboarding.id.to_s } ], "edges" => []))
      end

      get "#{easy_flow.manage_flow_canvas_path(parent)}.json"

      assert_equal easy_flow.manage_flow_path(onboarding, from: parent.public_code), response.parsed_body["nodes"].find { |node| node["id"] == "inner" }["opens"]
    end

    test "an inner flow's canvas opened from a Flow step links back to the parent flow's canvas" do
      parent = Definition.create!(host: "dummy", slug: "parent", title: "Parent")
      onboarding = Definition.create!(host: "dummy", slug: "onboarding", title: "Onboarding")

      get easy_flow.manage_flow_path(onboarding, from: parent.public_code)

      assert_select "a[href=?]", easy_flow.manage_flow_path(parent), text: "Back to Parent"
    end

    test "publishing a flow whose Flow step runs that same flow is refused" do
      looping = Definition.create!(host: "dummy", slug: "looping", title: "Looping")
      looping.publish_version(looping.definition_versions.create!(number: 1, definition: { "slug" => "looping" }))
      looping.update!(document: flowing("slug" => "looping", "entry" => "again", "nodes" => [ { "id" => "again", "type" => "flow_step", "flow" => looping.id.to_s, "version" => 1 } ], "edges" => []))

      post "#{easy_flow.manage_flow_canvas_path(looping)}/publish"

      assert_includes response.parsed_body["error"], "circular"
    end

    test "the canvas flags a Flow step that runs the flow it sits in" do
      looping = Definition.create!(host: "dummy", slug: "looping", title: "Looping")
      looping.publish_version(looping.definition_versions.create!(number: 1, definition: { "slug" => "looping" }))
      looping.update!(document: flowing("slug" => "looping", "entry" => "again", "nodes" => [ { "id" => "again", "type" => "flow_step", "flow" => looping.id.to_s, "version" => 1 } ], "edges" => []))

      get "#{easy_flow.manage_flow_canvas_path(looping)}.json"

      assert_includes response.parsed_body["violations"].map { |violation| [ violation["node"], violation["problem"] ] }, [ "again", "circular" ]
    end

    test "the canvas says a host that names no setting keeps insert buttons hidden" do
      get "#{canvas_path}.json"

      assert_equal false, response.parsed_body["always_show_insert_buttons"]
    end

    test "the canvas says a host that names no setting keeps step type codes showing" do
      get "#{canvas_path}.json"

      assert_equal false, response.parsed_body["hide_step_type_codes"]
    end

    test "the canvas says a host that asks to hide step type codes hides them" do
      EasyFlow.host_named("dummy").hide_step_type_codes = true

      get "#{canvas_path}.json"

      assert_equal true, response.parsed_body["hide_step_type_codes"]
    ensure
      EasyFlow.host_named("dummy").hide_step_type_codes = false
    end

    test "the canvas says a host that asks for insert buttons always shows them" do
      EasyFlow.host_named("dummy").always_show_insert_buttons = true

      get "#{canvas_path}.json"

      assert_equal true, response.parsed_body["always_show_insert_buttons"]
    ensure
      EasyFlow.host_named("dummy").always_show_insert_buttons = false
    end

    test "the canvas carries several saves to one step as one line" do
      2.times { patch "#{canvas_path}/steps/a", params: { config: { question: "New", answers: [ { "value" => "yes" } ] } } }

      get "#{canvas_path}.json"

      assert_equal 1, response.parsed_body["changes"].size
    end

    test "the history of versions lists every save a version captured" do
      2.times { patch "#{canvas_path}/steps/a", params: { config: { question: "New", answers: [ { "value" => "yes" } ] } } }
      post "#{canvas_path}/versions"

      get easy_flow.manage_flow_versions_path(flow)

      assert_select "[data-captured]", 2
    end

    test "the canvas carries the note a host sets for Publish" do
      EasyFlow.host_named("dummy").publish_note = "Publishing changes the live game."

      get "#{canvas_path}.json"

      assert_equal "Publishing changes the live game.", response.parsed_body["publish_note"]
    ensure
      EasyFlow.host_named("dummy").publish_note = nil
    end

    test "the builder header shows the back link its host set" do
      EasyFlow.host_named("dummy").back_link = { label: "Games", address: "/admin/games" }

      get easy_flow.manage_flow_path(flow)

      assert_select "header a[href=?]", "/admin/games", text: "Games"
    ensure
      EasyFlow.host_named("dummy").back_link = nil
    end

    test "the builder header shows no All flows button once its host set a back link" do
      EasyFlow.host_named("dummy").back_link = { label: "Games", address: "/admin/games" }

      get easy_flow.manage_flow_path(flow)

      assert_select "header a", text: "All flows", count: 0
    ensure
      EasyFlow.host_named("dummy").back_link = nil
    end

    test "the builder header shows All flows when its host set no back link" do
      get easy_flow.manage_flow_path(flow)

      assert_select "header a[href=?]", easy_flow.manage_flows_path, text: "All flows"
    end

    test "a request parameter does not change the back link's address" do
      EasyFlow.host_named("dummy").back_link = { label: "Games", address: "/admin/games" }

      get easy_flow.manage_flow_path(flow, back_link: "https://elsewhere.example", address: "https://elsewhere.example")

      assert_select "header a[href=?]", "https://elsewhere.example", count: 0
    ensure
      EasyFlow.host_named("dummy").back_link = nil
    end

    def leave_a_step_aside
      add_step_with_answers("aside")
      post "#{canvas_path}/edges", params: { from: "aside", to: "end" }
    end

    test "publishing a flow with an unconnected step names it in a warning and publishes nothing" do
      leave_a_step_aside

      post "#{canvas_path}/publish"

      assert_equal [ [ "aside", "New" ], nil ], [ response.parsed_body["unconnected"].first.values_at("id", "label"), flow.reload.live_version ]
    end

    test "accepting the warning at Create version gives a version without the unconnected steps" do
      leave_a_step_aside

      post "#{canvas_path}/versions", params: { remove_unconnected: [ "aside" ] }

      assert_equal %w[start a b end], flow.reload.definition_versions.order(:number).last.definition["nodes"].map { |node| node["id"] }
    end

    test "pressing Create version on a flow with an unconnected step names it in a warning" do
      leave_a_step_aside

      post "#{canvas_path}/versions"

      assert_equal [ "aside" ], response.parsed_body["unconnected"].map { |step| step["id"] }
    end

    test "accepting the warning at Publish makes live a version without the unconnected steps" do
      leave_a_step_aside

      post "#{canvas_path}/publish", params: { remove_unconnected: [ "aside" ] }

      assert_not_includes flow.reload.live_version.definition["nodes"].map { |node| node["id"] }, "aside"
    end

    test "accepting a warning that names other steps than the flow now has warns again and removes nothing" do
      leave_a_step_aside
      add_step_with_answers("later")

      post "#{canvas_path}/publish", params: { remove_unconnected: [ "aside" ] }

      assert_equal [ %w[aside later], nil, true ], [ response.parsed_body["unconnected"].map { |step| step["id"] }, flow.reload.live_version, nodes.include?("aside") ]
    end

    test "accepting while a step that stays has a problem refuses and removes nothing" do
      leave_a_step_aside
      post "#{canvas_path}/steps", params: { id: "gate", type: "condition", from: "b", to: "end" }

      post "#{canvas_path}/publish", params: { remove_unconnected: [ "aside" ] }

      assert_equal [ 422, nil, true ], [ response.status, flow.reload.live_version, nodes.include?("aside") ]
    end

    test "a problem only on the step being removed does not block" do
      post "#{canvas_path}/steps", params: { id: "aside", type: "question" }

      post "#{canvas_path}/publish", params: { remove_unconnected: [ "aside" ] }

      assert_equal flow.reload.definition_versions.order(:number).last, flow.live_version
    end
  end
end
