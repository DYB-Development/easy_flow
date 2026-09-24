module EasyFlow
  module Admission
    def self.of(flow, permitted:)
      raise NotPublished if flow.nil? || flow.live_definition.blank?
      raise NotPermitted unless permitted && flow.available?

      flow
    end

    def self.of_run(run, permitted: true)
      raise Withdrawn if run.definition_version.withdrawn?
      raise NotPermitted unless permitted && run.flow.available?

      run
    end
  end
end
