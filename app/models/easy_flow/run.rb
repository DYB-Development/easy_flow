module EasyFlow
  class Run < ApplicationRecord
    self.table_name = "easy_flow_runs"

    belongs_to :flow, class_name: "EasyFlow::Definition"
    belongs_to :definition_version, class_name: "EasyFlow::Version"
    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :parent_run, class_name: "EasyFlow::Run", optional: true
    has_many :inner_runs, class_name: "EasyFlow::Run", foreign_key: :parent_run_id, inverse_of: :parent_run, dependent: :nullify

    validate :started_on_a_published_version, on: :create

    def self.start(flow, version: flow.live_version)
      create!(flow: flow, definition_version: version)
    end

    def record(step_id, value)
      update!(recorded: visits.merge(step_id.to_s => { "value" => value, "completed_at" => Time.current.utc.iso8601 }))
    end

    def recorded
      visits.to_h { |step_id, visit| [ step_id.to_sym, visit["value"] ] }
    end

    def completed_at
      visits.select { |_step_id, visit| visit["completed_at"] }.to_h { |step_id, visit| [ step_id.to_sym, Time.zone.parse(visit["completed_at"]) ] }
    end

    def advance
      Runner.new(pinned_definition, host: EasyFlow.host_named(flow.host)).run(Progress::Kept.new(self))
    end

    def pinned_definition
      definition_version.definition.to_h
    end

    def next_step(state)
      digest.next_step(state.transform_keys(&:to_s), completed_at.transform_keys(&:to_s))
    end

    def output
      digest.output(recorded.transform_keys(&:to_s), completed_at.transform_keys(&:to_s))
    end

    def held_until
      stopped_at = next_step(recorded)
      Wait.held_until(digest.step(stopped_at.id), CompletedAt.latest(completed_at)) if stopped_at&.type == "wait"
    end

    def waiting_on
      stopped_at = next_step(recorded)
      inner_runs.find_by(parent_step: stopped_at.id) if stopped_at
    end

    def walked(state)
      digest.state_on_path(state.transform_keys(&:to_s), completed_at.transform_keys(&:to_s))
    end

    def digest
      @digest ||= Digest.new(Document.new(pinned_definition))
    end

    def discard_last
      last = walked(recorded).keys.map(&:to_sym).last
      update!(recorded: visits.except(last.to_s)) if last
    end

    def pinned_steps
      Array(definition_version.definition.to_h["nodes"]).index_by { |node| node["id"] }
    end

    private

    def visits
      read_attribute(:recorded).to_h
    end

    def started_on_a_published_version
      errors.add(:definition_version, "must be a published version of the flow") unless definition_version&.flow_id == flow_id && (definition_version.live? || definition_version.superseded?)
    end
  end
end
