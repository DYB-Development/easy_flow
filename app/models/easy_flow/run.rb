module EasyFlow
  class Run < ApplicationRecord
    self.table_name = "easy_flow_runs"

    belongs_to :flow, class_name: "EasyFlow::Definition"
    belongs_to :definition_version, class_name: "EasyFlow::Version"
    belongs_to :owner, polymorphic: true, optional: true

    def self.start(flow)
      create!(flow: flow, definition_version: flow.live_version)
    end

    def record(step_id, value)
      update!(recorded: recorded.merge(step_id => value))
    end

    def recorded
      super.to_h.symbolize_keys
    end

    def pinned_definition
      definition_version.definition.to_h
    end

    def next_step(state)
      digest.next_step(state.transform_keys(&:to_s))
    end

    def walked(state)
      digest.state_on_path(state.transform_keys(&:to_s))
    end

    def digest
      @digest ||= Digest.new(Document.new(pinned_definition))
    end

    def discard_last
      last = walked(recorded).keys.map(&:to_sym).last
      update!(recorded: recorded.except(last)) if last
    end

    def pinned_steps
      Array(definition_version.definition.to_h["nodes"]).index_by { |node| node["id"] }
    end
  end
end
