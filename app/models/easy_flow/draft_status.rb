module EasyFlow
  class DraftStatus
    def initialize(flow)
      @flow = flow
    end

    def to_s
      "#{based_on} · unsaved #{changes} #{"change".pluralize(changes)}"
    end

    def publishes
      return version.number if version && @flow.document == version.definition

      @flow.definition_versions.maximum(:number).to_i + 1
    end

    def number
      version&.number
    end

    private

    def version
      return @version if defined?(@version)

      @version = @flow.current_definition_version
    end

    def based_on
      version ? "draft from v#{version.number}" : "new draft"
    end

    def changes
      Change.listed(@flow.changes_since_version.to_a).size
    end
  end
end
