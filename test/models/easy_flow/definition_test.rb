require "test_helper"

module EasyFlow
  class DefinitionTest < ActiveSupport::TestCase
    test "two hosts can each hold a flow under the same slug" do
      Definition.create!(host: "alembic", slug: "intake")
      Definition.create!(host: "console", slug: "intake")

      assert_equal 2, Definition.where(slug: "intake").count
    end

    test "keeps nothing of a run until it is told to" do
      assert_predicate Definition.create!(slug: "fresh"), :unsaved?
    end

    test "begins with a step that starts the flow and one that ends it" do
      flow = Definition.create!(slug: "fresh")

      assert_equal [ "start", "terminal" ], flow.document["nodes"].map { |node| node["type"] }
    end

    test "leads from where it begins to where it ends" do
      flow = Definition.create!(slug: "fresh")

      assert_equal [ { "from" => "start", "to" => "end" } ], flow.document["edges"]
    end

    test "begins sound, with nothing to report" do
      flow = Definition.create!(slug: "fresh")

      assert_empty Validator.new(Document.new(flow.document)).violations
    end

    test "reports when it is hidden" do
      assert Definition.new(status: :hidden).hidden?
    end

    test "reports its kind" do
      assert Definition.new(kind: :scored).scored?
    end

    test "builds a runner from the version it published" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition({ "slug" => "demo" })
      flow.publish

      assert_equal "demo", flow.runner.slug
    end

    test "recording a definition stores it as a version" do
      flow = Definition.create!(slug: "demo")

      flow.record_definition({ "slug" => "demo" })

      assert_equal({ "slug" => "demo" }, flow.definition_versions.last.definition)
    end

    test "recording a second definition takes the next version number" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition({ "slug" => "first" })

      flow.record_definition({ "slug" => "second" })

      assert_equal 2, flow.definition_versions.last.number
    end

    def edited(flow, entry, before)
      flow.update!(document: { "entry" => entry }, undone_changes: [],
        changes_since_version: flow.changes_since_version.to_a +
          [ { "action" => "updated", "steps" => [], "named" => [], "before" => before } ])
    end

    test "undoing puts back the document as it was before the change" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })

      flow.edit_history.undo_change

      assert_equal({ "entry" => "one" }, flow.reload.document)
    end

    test "redoing puts the change back" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })
      flow.edit_history.undo_change

      flow.edit_history.redo_change

      assert_equal({ "entry" => "two" }, flow.reload.document)
    end

    test "undoing records no version" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })

      assert_no_difference -> { flow.definition_versions.count } do
        flow.edit_history.undo_change
      end
    end

    test "there is nothing to undo before anything is changed" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })

      assert_not flow.edit_history.undoable?
    end

    test "there is nothing to redo until something is undone" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })

      assert_not flow.edit_history.redoable?
    end

    test "undoing with nothing behind it leaves the document alone" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })

      flow.edit_history.undo_change

      assert_equal({ "entry" => "one" }, flow.reload.document)
    end

    test "creating a version leaves nothing to redo but keeps what can be undone" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })
      flow.edit_history.undo_change

      flow.create_version

      assert_not flow.edit_history.redoable?
    end

    test "creating a version leaves the author able to undo past it" do
      flow = Definition.create!(slug: "undo", document: { "entry" => "one" })
      edited(flow, "two", { "entry" => "one" })

      flow.create_version

      assert_predicate flow.edit_history, :undoable?
    end

    test "reports its current definition as the highest-numbered version" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition({ "slug" => "first" })
      flow.record_definition({ "slug" => "second" })

      assert_equal({ "slug" => "second" }, flow.definition)
    end

    test "upserting records the host the flow is seeded for" do
      Definition.upsert_definition({ "slug" => "seeded" }, host: "alembic")

      assert_equal "alembic", Definition.find_by(slug: "seeded").host
    end

    test "upserting records the imported definition as a version" do
      Definition.upsert_definition({ "slug" => "seeded", "headline" => "Hi" }, host: "dummy")

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Definition.find_by(slug: "seeded").definition_versions.last.definition)
    end

    test "upserting an unchanged definition records no new version" do
      2.times { Definition.upsert_definition({ "slug" => "seeded", "headline" => "Hi" }, host: "dummy") }

      assert_equal 1, Definition.find_by(slug: "seeded").definition_versions.count
    end

    test "upserts a flow storing the definition keyed by its slug" do
      Definition.upsert_definition({ "slug" => "seeded", "headline" => "Hi" }, host: "dummy")

      assert_equal({ "slug" => "seeded", "headline" => "Hi" }, Definition.find_by(slug: "seeded").definition)
    end

    test "upserting the same slug twice keeps a single flow" do
      2.times { Definition.upsert_definition({ "slug" => "seeded" }, host: "dummy") }

      assert_equal 1, Definition.where(slug: "seeded").count
    end

    test "can be deleted once a definition has been recorded" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("slug" => "demo")

      assert_difference -> { Definition.count }, -1 do
        flow.destroy!
      end
    end

    test "holds a live document that can be edited" do
      flow = Definition.create!(slug: "demo")

      flow.update!(document: { "entry" => "a", "nodes" => [], "edges" => [] })

      assert_equal "a", flow.reload.document["entry"]
    end

    test "starts with nothing changed since its last version" do
      flow = Definition.create!(slug: "demo")

      assert_empty flow.changes_since_version.to_a
    end

    test "recording a first definition gives the flow a document to edit" do
      flow = Definition.create!(slug: "demo")

      flow.record_definition("entry" => "a", "nodes" => [], "edges" => [])

      assert_equal "a", flow.reload.document["entry"]
    end

    test "creating a version records the live document" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      flow.update!(document: { "entry" => "b", "nodes" => [], "edges" => [] })

      flow.create_version

      assert_equal "b", flow.definition_versions.order(:number).last.definition["entry"]
    end

    test "creating a version clears what had changed since the last one" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      flow.update!(document: { "entry" => "b" }, changes_since_version: [ { "action" => "moved", "steps" => [ "a" ], "named" => [ "A" ] } ])

      flow.create_version

      assert_empty flow.reload.changes_since_version
    end

    test "creating a version twice over records only one" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("entry" => "a", "nodes" => [], "edges" => [])

      assert_no_difference -> { flow.definition_versions.count } do
        flow.create_version
      end
    end

    test "publishing marks the created version as the one visitors run" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("entry" => "a", "nodes" => [], "edges" => [])
      flow.update!(document: { "entry" => "b", "nodes" => [], "edges" => [] })

      flow.publish

      assert_equal "b", flow.reload.live_version.definition["entry"]
    end

    test "a version carries the changes that produced it" do
      flow = Definition.create!(slug: "demo", document: { "entry" => "a" })
      flow.update!(changes_since_version: [ { "action" => "added", "steps" => [ "a" ], "named" => [ "A" ] } ])

      flow.create_version

      assert_equal [ "added" ], flow.definition_versions.last.changes.map { |change| change["action"] }
    end

    test "returning to a version makes its content the live document" do
      flow = Definition.create!(slug: "demo")
      flow.record_definition("entry" => "first")
      first = flow.definition_versions.last
      flow.update!(document: { "entry" => "later" })

      flow.return_to(first)

      assert_equal({ "entry" => "first" }, flow.reload.document)
    end

    test "returning to a version leaves every version in place" do
      flow = returnable
      first = flow.definition_versions.order(:number).first

      assert_no_difference -> { flow.definition_versions.count } do
        flow.return_to(first)
      end
    end

    test "returning to a version leaves that version's content alone" do
      flow = returnable
      first = flow.definition_versions.order(:number).first

      flow.return_to(first)

      assert_equal({ "entry" => "first" }, first.reload.definition)
    end

    test "returning records that the document was returned" do
      flow = returnable
      first = flow.definition_versions.order(:number).first

      flow.return_to(first)

      assert_equal "Returned to version 1", Change.phrase(flow.reload.changes_since_version.last)
    end

    test "refuses a version belonging to another flow" do
      flow = returnable
      stranger = Definition.create!(slug: "stranger")
      stranger.record_definition("entry" => "theirs")

      assert_raises(ActiveRecord::RecordNotFound) { flow.return_to(stranger.definition_versions.last) }
    end

    test "returning leaves visitors on the version they were running" do
      flow = returnable
      flow.publish
      running = flow.live_version

      flow.return_to(flow.definition_versions.order(:number).first)

      assert_equal running, flow.reload.live_version
    end

    test "undoing a return puts the document back" do
      flow = returnable
      flow.return_to(flow.definition_versions.order(:number).first)

      flow.edit_history.undo_change

      assert_equal({ "entry" => "second" }, flow.reload.document)
    end

    def returnable
      Definition.create!(slug: "returnable").tap do |flow|
        flow.record_definition("entry" => "first")
        flow.record_definition("entry" => "second")
      end
    end

    test "publishing makes the version live" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })

      flow.publish

      assert_predicate flow.current_definition_version, :live?
    end

    test "publishing a newer version supersedes the one that was live" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      first = flow.current_definition_version

      flow.update!(document: { "slug" => "demo", "entry" => "a" })
      flow.publish

      assert_predicate first.reload, :superseded?
    end

    test "publishing the version that is already live leaves it live" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish

      flow.publish

      assert_predicate flow.current_definition_version.reload, :live?
    end

    test "a retired version is no longer the live one" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish

      flow.retire_version(flow.live_version)

      assert_nil flow.reload.live_version
    end

    test "a retired version cannot be published" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      retired = flow.live_version
      flow.retire_version(retired)

      assert_raises(OutOfService) { flow.publish_version(retired) }
    end

    test "a retired version cannot be returned to" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      retired = flow.live_version
      flow.retire_version(retired)

      assert_raises(OutOfService) { flow.return_to(retired) }
    end

    test "a flow is active until it is set otherwise" do
      flow = Definition.create!(slug: "demo")

      assert_predicate flow, :active?
    end

    test "a hidden flow is left out of the listable ones" do
      flow = Definition.create!(slug: "demo", status: :hidden)

      assert_not_includes Definition.listable, flow
    end

    test "an active flow is among the listable ones" do
      flow = Definition.create!(slug: "demo")

      assert_includes Definition.listable, flow
    end

    test "only one version of a flow can be live" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      other = flow.definition_versions.create!(number: 2, definition: { "slug" => "demo" })

      assert_raises(ActiveRecord::RecordNotUnique) { other.update!(status: :live) }
    end

    test "a withdrawn version cannot be published" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      withdrawn = flow.live_version
      withdrawn.update!(status: :withdrawn)

      assert_raises(OutOfService) { flow.publish_version(withdrawn) }
    end

    test "a withdrawn version cannot be returned to" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      withdrawn = flow.live_version
      withdrawn.update!(status: :withdrawn)

      assert_raises(OutOfService) { flow.return_to(withdrawn) }
    end

    test "a version survives being withdrawn so a finished run stays readable" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish
      version = flow.live_version

      version.update!(status: :withdrawn)

      assert_equal({ "slug" => "demo" }, version.reload.definition)
    end

    test "withdrawing a version takes it out of service" do
      flow = Definition.create!(slug: "demo", document: { "slug" => "demo" })
      flow.publish

      flow.withdraw_version(flow.live_version)

      assert_predicate flow.definition_versions.first.reload, :withdrawn?
    end
  end
end
