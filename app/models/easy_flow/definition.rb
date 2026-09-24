module EasyFlow
  class Definition < ApplicationRecord
    self.table_name = "easy_flow_definitions"

    enum :status, { active: "active", hidden: "hidden", inactive: "inactive" }
    enum :kind, { scored: "scored", guide: "guide" }
    enum :persists, { unsaved: "unsaved", each_step: "each_step", on_finish: "on_finish" }

    validates :host, :slug, presence: true

    after_initialize :begin_the_flow, if: :new_record?

    scope :listable, -> { active }

    # Declared before :definition_versions so runs clear first, otherwise
    # destroying a flow trips the runs -> definition_versions FK.
    has_many :runs, class_name: "EasyFlow::Run", foreign_key: :flow_id, dependent: :destroy
    has_many :definition_versions, class_name: "EasyFlow::Version", foreign_key: :flow_id, dependent: :destroy

    def self.upsert_definition(definition, host:)
      find_or_initialize_by(host: host, slug: definition["slug"]).tap do |flow|
        flow.save!
        flow.record_definition(definition) unless flow.definition == definition
      end
    end

    def definition
      current_definition_version&.definition
    end

    def current_definition_version
      definition_versions.find_by(number: cursor)
    end

    def edit_history
      @edit_history ||= EditHistory.new(self)
    end

    def publish
      create_version

      publish_version(current_definition_version)
    end

    def return_to(version)
      raise ActiveRecord::RecordNotFound unless definition_versions.exists?(version.id)
      raise OutOfService if version.out_of_service?

      update!(document: version.definition, undone_changes: [],
        changes_since_version: changes_since_version.to_a + [ returning_to(version) ])
    end

    def create_version
      record_definition(document, changes_since_version.to_a) unless versioned?

      update!(undo_history: edit_history.undoable, changes_since_version: [], undone_changes: [])
    end

    def returning_to(version)
      { "action" => "returned", "steps" => [], "named" => [],
        "detail" => "version #{version.number}", "before" => document }
    end

    def versioned?
      document == definition
    end

    def record_definition(payload, captured = [])
      definition_versions.create!(number: next_definition_number, definition: payload,
        changes_captured: captured.map { |change| change.except("before") })
        .tap { |version| update!(definition_cursor: version.number, document: payload) }
    end

    def publish_version(version)
      raise OutOfService if version.out_of_service?
      return if live_version == version

      live_version&.update!(status: :superseded)
      version.update!(status: :live)
    end

    def available?
      !inactive?
    end

    def retire_version(version)
      version.update!(status: :retired)
    end

    def withdraw_version(version)
      version.update!(status: :withdrawn)
    end

    def live_version
      definition_versions.find_by(status: :live)
    end

    def live_definition
      live_version&.definition
    end

    def runner
      Runner.new(live_definition)
    end

    private

    def begin_the_flow
      self.document ||= { "nodes" => [ { "id" => "start", "type" => "start" }, { "id" => "end", "type" => "terminal" } ],
                          "edges" => [ { "from" => "start", "to" => "end" } ] }
    end

    def cursor
      definition_cursor || recorded_numbers.max
    end

    def recorded_numbers
      definition_versions.pluck(:number)
    end

    def next_definition_number
      (definition_versions.maximum(:number) || 0) + 1
    end
  end
end
