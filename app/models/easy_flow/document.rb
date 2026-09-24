module EasyFlow
  class Document
    def initialize(document, registry: EasyFlow.registry)
      @document = document
      @registry = registry
    end

    def nodes
      Array(@document["nodes"]).map { |node| Node.new(id: node["id"], type: node["type"], config: node.except("id", "type")) }
    end

    def edges
      Array(@document["edges"]).map { |edge| Edge.new(from: edge["from"], to: edge["to"], on: edge["on"]) }
    end

    def entry
      beginnings.first
    end

    def beginnings
      nodes.select { |node| begins_here?(node) }.map(&:id)
    end

    def begins_here?(node)
      @registry.registered?(node.type) && @registry.fetch(node.type).begins_here?
    end

    def node(id)
      nodes.find { |node| node.id == id }
    end

    def edges_from(id)
      edges.select { |edge| edge.from == id }
    end

    def reachable(without: nil)
      found = []
      frontier = [ entry ]

      while (id = frontier.shift)
        next if found.include?(id) || id == without

        found << id
        frontier.concat(edges_from(id).map(&:to))
      end

      found
    end

    def to_h
      @document
    end

    def insert(node, on:, leaving: nil)
      source, target = on
      replaced = raw_edges.find { |edge| edge["from"] == source && edge["to"] == target }
      bridged = [ { "from" => source, "to" => node["id"], "on" => replaced&.fetch("on", nil) }.compact,
                  { "from" => node["id"], "to" => target, "on" => leaving }.compact ]

      with(nodes: raw_nodes + [ node ], edges: (raw_edges - [ replaced ]) + bridged)
    end

    def add(node)
      with(nodes: raw_nodes + [ node ], edges: raw_edges)
    end

    def connect(from:, to:, on: nil)
      with(nodes: raw_nodes, edges: raw_edges + [ { "from" => from, "to" => to, "on" => on }.compact ])
    end

    def disconnect(from:, to:)
      with(nodes: raw_nodes, edges: raw_edges.reject { |edge| edge["from"] == from && edge["to"] == to })
    end

    def move(id, on:, leaving: nil)
      step = raw_nodes.find { |node| node["id"] == id }
      return self unless step

      remove(id).insert(step, on: on, leaving: leaving)
    end

    def configure(id, config)
      reconfigured = raw_nodes.map do |node|
        node["id"] == id ? node.slice("id", "type").merge(config) : node
      end

      with(nodes: reconfigured, edges: raw_edges)
    end

    def rewire(from:, to:, target:)
      rewritten = raw_edges.map do |edge|
        edge["from"] == from && edge["to"] == to ? edge.merge("to" => target) : edge
      end

      with(nodes: raw_nodes, edges: rewritten)
    end

    def remove(id)
      incoming = raw_edges.select { |edge| edge["to"] == id }
      outgoing = raw_edges.select { |edge| edge["from"] == id }

      with(nodes: raw_nodes.reject { |node| node["id"] == id },
           edges: (raw_edges - incoming - outgoing) + bridges(incoming, outgoing))
    end

    private

    def bridges(incoming, outgoing)
      incoming.product(outgoing).map do |arriving, leaving|
        { "from" => arriving["from"], "to" => leaving["to"], "on" => arriving["on"] }.compact
      end
    end

    def raw_nodes
      Array(@document["nodes"])
    end

    def raw_edges
      Array(@document["edges"])
    end

    def with(nodes:, edges:)
      Document.new(@document.merge("nodes" => nodes, "edges" => edges), registry: @registry).tap do |edited|
        broken = Validator.new(edited, registry: @registry).malformations
        raise InvalidEdit, broken.map { |violation| "#{violation.node}: #{violation.problem}" }.join(", ") if broken.any?
      end
    end
  end
end
