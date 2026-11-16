module EasyFlow
  class CheckList
    ALWAYS = {
      "Every connection joins two steps that exist." => %w[missing_edge_target missing_edge_source],
      "Every step has an id of its own that a flow can use." => %w[duplicate_id reserved_id],
      "The flow has one start step, and nothing leads into it." => %w[no_beginning many_beginnings before_the_beginning],
      "Every step can be reached from the start." => %w[unreachable],
      "Every step comes after the steps it reads." => %w[unmet_requirement reading_an_unconnected_step],
      "Every step has the settings it needs." => %w[missing_setting missing_value],
      "Every flow a step starts can run and does not lead back here." => %w[missing_flow unrunnable_version owned_by_another_owner circular]
    }.freeze

    OPTIONAL = {
      unrouted_value: { "Every answer leads to a next step." => %w[unrouted_value] },
      unfollowed_path: { "Every path out of a step is connected." => %w[unfollowed_path] },
      dead_end: { "Every path ends at an End step." => %w[dead_end past_the_end] }
    }.freeze

    def initialize(violations, checks: EasyFlow.checks)
      @violations = violations
      @checks = checks
    end

    def rows
      errors + passed
    end

    private

    def errors
      @violations.map { |violation| { "level" => "error", "node" => violation["node"], "sentence" => violation["sentence"] } }
    end

    def passed
      made.reject { |_sentence, problems| problems.intersect?(found) }.keys
        .map { |sentence| { "level" => "ok", "node" => nil, "sentence" => sentence } }
    end

    def made
      ALWAYS.merge(*@checks.map { |name| OPTIONAL.fetch(name) })
    end

    def found
      @violations.map { |violation| violation["problem"] }
    end
  end
end
