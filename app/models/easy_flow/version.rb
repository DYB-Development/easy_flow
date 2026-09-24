module EasyFlow
  class Version < ApplicationRecord
    self.table_name = "easy_flow_versions"

    enum :status, { draft: "draft", live: "live", superseded: "superseded",
                    retired: "retired", withdrawn: "withdrawn" }

    belongs_to :flow, class_name: "EasyFlow::Definition"

    validates :number, uniqueness: { scope: :flow_id }

    def out_of_service?
      retired? || withdrawn?
    end

    def changes
      changes_captured.to_a
    end

    FROZEN = %w[definition number flow_id changes_captured].freeze

    before_update { raise ActiveRecord::ReadOnlyRecord if changed.intersect?(FROZEN) }
  end
end
