require "test_helper"

module EasyFlow
  class VersionTest < ActiveSupport::TestCase
    test "is invalid when the flow already has that version number" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      duplicate = flow.definition_versions.build(number: 1, definition: { "slug" => "demo" })

      assert_not duplicate.valid?
    end

    test "is valid when a different flow already has that version number" do
      Definition.create!(host: "dummy", slug: "taken").definition_versions.create!(number: 1, definition: { "slug" => "taken" })
      flow = Definition.create!(host: "dummy", slug: "demo")

      version = flow.definition_versions.build(number: 1, definition: { "slug" => "demo" })

      assert version.valid?
    end

    test "refuses to be updated once persisted" do
      flow = Definition.create!(host: "dummy", slug: "demo")
      version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(definition: { "slug" => "rewritten" }) }
    end

    test "a version that has been created but never published is a draft" do
      flow = Definition.create!(host: "dummy", slug: "demo")

      version = flow.definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      assert_predicate version, :draft?
    end

    test "its status may change" do
      version = Definition.create!(host: "dummy", slug: "demo").definition_versions.create!(number: 1, definition: { "slug" => "demo" })

      version.update!(status: :live)

      assert_predicate version.reload, :live?
    end
  end
end
