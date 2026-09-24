module EasyFlow
  module Drawing
    def self.of(node, registry = EasyFlow.registry)
      named(node, registry).presence || EasyFlow.drawing
    end

    def self.named(node, registry)
      return unless node && registry.registered?(node.type)

      registry.fetch(node.type).drawn_by
    end
  end
end
