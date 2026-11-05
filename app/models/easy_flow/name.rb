module EasyFlow
  module Name
    def self.of(node, registry = EasyFlow.registry)
      return "" unless node

      named(node, registry) || node.id
    end

    def self.shown(node, registry = EasyFlow.registry)
      named(node, registry) || type_name(node, registry) || "Unnamed step"
    end

    def self.named(node, registry)
      registry.fetch(node.type).name_of(node) if registry.registered?(node.type)
    end

    def self.type_name(node, registry)
      registry.fetch(node.type).step_name if registry.registered?(node.type)
    end
  end
end
