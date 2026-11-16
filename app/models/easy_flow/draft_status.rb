module EasyFlow
  class DraftStatus
    def initialize(flow)
      @flow = flow
    end

    def to_s
      "draft from v#{@flow.current_definition_version.number} · unsaved #{changes} #{"change".pluralize(changes)}"
    end

    private

    def changes
      Change.listed(@flow.changes_since_version.to_a).size
    end
  end
end
