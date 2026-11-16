module EasyFlow
  class DraftStatus
    def initialize(flow)
      @flow = flow
    end

    def to_s
      "#{based_on} · unsaved #{changes} #{"change".pluralize(changes)}"
    end

    def publishes
      return @flow.current_definition_version.number if @flow.current_definition_version && @flow.versioned?

      @flow.definition_versions.maximum(:number).to_i + 1
    end

    private

    def based_on
      version = @flow.current_definition_version
      version ? "draft from v#{version.number}" : "new draft"
    end

    def changes
      Change.listed(@flow.changes_since_version.to_a).size
    end
  end
end
