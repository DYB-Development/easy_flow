module EasyFlow
  module Name
    def self.of(node, registry = EasyFlow.registry)
      return "" unless node

      named(node, registry) || node.id
    end

    def self.named(node, registry)
      registry.fetch(node.type).name_of(node) if registry.registered?(node.type)
    end
  end
end
