module EasyFlow
  class Layout
    SPREAD = 2

    def initialize(document)
      @document = document
    end

    def positions
      rows = depths
      columns = columns_for(rows)

      rows.to_h { |id, row| [ id, { "row" => row, "column" => columns[id] } ] }
    end

    private

    def depths
      walked = walk_from_entry

      walked.merge(stranded(walked).index_with(next_row(walked)))
    end

    def walk_from_entry
      seen = {}
      frontier = starting_points.map { |id| [ id, 0 ] }

      until frontier.empty?
        id, depth = frontier.shift
        next if seen.key?(id)

        seen[id] = depth
        @document.edges_from(id).each { |edge| frontier << [ edge.to, depth + 1 ] if known?(edge.to) }
      end

      seen
    end

    def starting_points
      return [ @document.entry ] if known?(@document.entry)

      arrived = @document.edges.map(&:to)
      @document.nodes.map(&:id).reject { |id| arrived.include?(id) }
    end

    def columns_for(rows)
      @columns = {}
      @next_leaf = 0
      rows.keys.each { |id| place(id, branches(rows)) }
      @columns
    end

    def branches(rows)
      claimed = {}

      rows.keys.to_h do |id|
        mine = @document.edges_from(id).map(&:to).uniq
          .select { |child| rows[child] == rows[id] + 1 && !claimed.key?(child) }
        mine.each { |child| claimed[child] = true }
        [ id, mine ]
      end
    end

    def place(id, branches)
      return @columns[id] if @columns.key?(id)

      mine = branches[id].to_a
      return @columns[id] = (@next_leaf += SPREAD) - SPREAD if mine.empty?

      spans = mine.map { |child| place(child, branches) }
      @columns[id] = (spans.min + spans.max) / 2
    end

    def stranded(walked)
      @document.nodes.map(&:id).uniq - walked.keys
    end

    def next_row(walked)
      (walked.values.max || -1) + 1
    end

    def known?(id)
      @document.node(id).present?
    end
  end
end
