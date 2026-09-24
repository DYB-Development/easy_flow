module EasyFlow
  class Validator
    OPTIONAL = { unrouted_value: :unrouted_values, unfollowed_path: :unfollowed_paths, dead_end: :dead_ends }.freeze

    def initialize(document, registry: EasyFlow.registry, checks: EasyFlow.checks)
      @document = document
      @registry = registry
      @checks = checks
    end

    def violations
      structural_violations + unmet_requirements + missing_settings + missing_values + beginnings + asked_for
    end

    def structural_violations
      malformations + unreachable
    end

    def malformations
      missing_edge_targets + missing_edge_sources + duplicate_ids + no_beginning
    end

    private

    def asked_for
      @checks.flat_map { |name| send(OPTIONAL.fetch(name)) }
    end

    def missing_edge_targets
      @document.edges.reject { |edge| known?(edge.to) }
        .map { |edge| Violation.new(node: edge.from, problem: :missing_edge_target, detail: edge.to) }
    end

    def missing_edge_sources
      @document.edges.reject { |edge| known?(edge.from) }
        .map { |edge| Violation.new(node: edge.to, problem: :missing_edge_source, detail: edge.from) }
    end

    def duplicate_ids
      @document.nodes.map(&:id).tally.select { |_id, count| count > 1 }
        .map { |id, _count| Violation.new(node: id, problem: :duplicate_id) }
    end

    def no_beginning
      return [] if known?(@document.entry)

      [ Violation.new(node: nil, problem: :no_beginning) ]
    end

    def unmet_requirements
      @document.nodes.flat_map do |node|
        requirements_for(node).reject { |required| precedes_every_path?(required, node.id) }
          .map { |required| Violation.new(node: node.id, problem: :unmet_requirement, detail: required) }
      end
    end

    def dead_ends
      @document.nodes.filter_map { |node| ending_problem(node) }
    end

    def ending_problem(node)
      leaving = @document.edges_from(node.id).any?
      return Violation.new(node: node.id, problem: :past_the_end) if ends_here?(node) && leaving
      return if ends_here?(node) || leaving

      Violation.new(node: node.id, problem: :dead_end)
    end

    def ends_here?(node)
      @registry.registered?(node.type) && @registry.fetch(node.type).ends_here?
    end

    def unfollowed_paths
      @document.nodes.select { |node| leads_on?(node) }.flat_map { |node| unfollowed_paths_from(node) }
    end

    def leads_on?(node)
      @registry.registered?(node.type) && !@registry.fetch(node.type).routes?
    end

    def unfollowed_paths_from(node)
      @document.edges_from(node.id).drop(1)
        .map { |edge| Violation.new(node: node.id, problem: :unfollowed_path, detail: edge.to) }
    end

    def unrouted_values
      @document.nodes.flat_map { |node| unrouted_values_in(node) }
    end

    def unrouted_values_in(node)
      wired = @document.edges_from(node.id).map { |edge| edge.on.to_s }

      digest.routing_values(node.id).reject { |value| wired.include?(value) }
        .map { |value| Violation.new(node: node.id, problem: :unrouted_value, detail: value) }
    end

    def digest
      Digest.new(@document, registry: @registry)
    end

    def beginnings
      @document.beginnings.drop(1).map { |id| Violation.new(node: id, problem: :many_beginnings) } + led_into
    end

    def led_into
      @document.beginnings.select { |id| @document.edges.any? { |edge| edge.to == id } }
        .map { |id| Violation.new(node: id, problem: :before_the_beginning) }
    end

    def missing_values
      @document.nodes.flat_map { |node| missing_values_in(node) }
    end

    def missing_values_in(node)
      drawn_of(node).filter_map do |name, source|
        chosen = node.config[name.to_s]
        next if chosen.blank? || node.config[source.to_s].blank?
        next if offered_to(node, source).include?(chosen.to_s)

        Violation.new(node: node.id, problem: :missing_value, detail: chosen.to_s)
      end
    end

    def offered_to(node, source)
      naming = @registry.fetch(node.type).settings.outputs_of[source]

      digest.values_of(node.config[naming.to_s], node.config[source.to_s]).map { |value| value["value"].to_s }
    end

    def drawn_of(node)
      return {} unless @registry.registered?(node.type)

      @registry.fetch(node.type).settings.drawn_from
    end

    def missing_settings
      @document.nodes.flat_map do |node|
        required_of(node).reject { |name| node.config[name.to_s].present? }
          .map { |name| Violation.new(node: node.id, problem: :missing_setting, detail: name.to_s) }
      end
    end

    def required_of(node)
      return [] unless @registry.registered?(node.type)

      @registry.fetch(node.type).settings.required
    end

    def requirements_for(node)
      return [] unless @registry.registered?(node.type)

      @registry.fetch(node.type).settings.requirements_for(node.config)
    end

    def precedes_every_path?(required, id)
      known?(required) && !@document.reachable(without: required).include?(id)
    end

    def unreachable
      return [] unless known?(@document.entry)

      (@document.nodes.map(&:id).uniq - @document.reachable).map { |id| Violation.new(node: id, problem: :unreachable) }
    end

    def known?(id)
      @document.node(id).present?
    end
  end
end
