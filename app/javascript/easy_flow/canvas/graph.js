const columnsOf = (ids, edges) => {
  const columns = new Map(ids.map((id) => [ id, 0 ]))
  const outgoing = new Map(ids.map((id) => [ id, [] ]))
  const waiting = new Map(ids.map((id) => [ id, 0 ]))
  edges.forEach((edge) => {
    outgoing.get(edge.source).push(edge.target)
    waiting.set(edge.target, waiting.get(edge.target) + 1)
  })

  const ready = ids.filter((id) => waiting.get(id) === 0)
  for (let at = 0; at < ready.length; at++) {
    const id = ready[at]
    outgoing.get(id).forEach((target) => {
      columns.set(target, Math.max(columns.get(target), columns.get(id) + 1))
      waiting.set(target, waiting.get(target) - 1)
      if (waiting.get(target) === 0) ready.push(target)
    })
  }

  return columns
}

const outgoingOf = (ids, edges) => {
  const outgoing = new Map(ids.map((id) => [ id, [] ]))
  edges.forEach((edge) => outgoing.get(edge.source).push(edge))
  return outgoing
}

const loopingBack = (ids, edges) => {
  const outgoing = outgoingOf(ids, edges)
  const entered = new Set(edges.map((edge) => edge.target))
  const state = new Map()
  const backward = new Set()

  const walk = (root) => {
    const stack = [ [ root, 0 ] ]
    state.set(root, "open")
    while (stack.length > 0) {
      const top = stack[stack.length - 1]
      const edge = outgoing.get(top[0])[top[1]++]
      if (!edge) {
        state.set(top[0], "done")
        stack.pop()
      } else if (state.get(edge.target) === "open") backward.add(edge)
      else if (!state.has(edge.target)) {
        state.set(edge.target, "open")
        stack.push([ edge.target, 0 ])
      }
    }
  }

  ids.filter((id) => !entered.has(id)).forEach(walk)
  ids.forEach((id) => { if (!state.has(id)) walk(id) })

  return backward
}

const rowsOf = (ids, forward, columns) => {
  const stacks = []
  ids.forEach((id) => (stacks[columns.get(id)] ||= []).push(id))
  const outgoing = outgoingOf(ids, forward)
  const exits = new Map()
  outgoing.forEach((leaving) => leaving.forEach((edge, at) => exits.set(edge, (at + 1) / (leaving.length + 1))))
  const incoming = new Map(ids.map((id) => [ id, [] ]))
  forward.forEach((edge) => incoming.get(edge.target).push(edge))
  const rows = new Map()

  stacks.forEach((stack) => {
    const keyOf = new Map(stack.map((id) => {
      const from = incoming.get(id)
      const total = from.reduce((sum, edge) => sum + rows.get(edge.source) + exits.get(edge), 0)
      return [ id, from.length > 0 ? total / from.length : Infinity ]
    }))
    stack.sort((a, b) => (keyOf.get(a) === keyOf.get(b) ? 0 : keyOf.get(a) < keyOf.get(b) ? -1 : 1))
    stack.forEach((id, row) => rows.set(id, row))
  })

  return rows
}

export const CARD_WIDTH = 184
export const CARD_HEIGHT = 64
export const COLUMN_GAP = 136
export const ROW_GAP = 32
export const MARGIN = 40
export const EXIT = 80
export const CHANNEL_GAP = 14

const startsOf = (sizes, gap, from) => {
  const starts = []
  sizes.forEach((size, at) => { starts[at] = at === 0 ? from : starts[at - 1] + sizes[at - 1] + gap })
  return starts
}

export const layOut = (nodes, edges, { heights = {} } = {}) => {
  const ids = nodes.map((node) => node.id)
  const backward = loopingBack(ids, edges)
  const forward = edges.filter((edge) => !backward.has(edge))
  const columns = columnsOf(ids, forward)
  const rows = rowsOf(ids, forward, columns)
  const widthOf = () => CARD_WIDTH
  const heightOf = (id) => heights[id] || CARD_HEIGHT

  const columnWidths = []
  const rowHeights = []
  ids.forEach((id) => {
    columnWidths[columns.get(id)] = Math.max(columnWidths[columns.get(id)] || 0, widthOf(id))
    rowHeights[rows.get(id)] = Math.max(rowHeights[rows.get(id)] || 0, heightOf(id))
  })
  const skipping = (edge) => columns.get(edge.target) > columns.get(edge.source) + 1
  const channelsOf = (taken) => {
    const channels = new Map()
    taken.forEach((edge) => { if (!channels.has(edge.target)) channels.set(edge.target, channels.size) })
    return channels
  }
  const above = channelsOf(edges.filter((edge) => backward.has(edge)))
  const below = channelsOf(forward.filter(skipping))

  const lefts = startsOf(columnWidths, COLUMN_GAP, COLUMN_GAP - EXIT + MARGIN / 2)
  const tops = startsOf(rowHeights, ROW_GAP, MARGIN + above.size * CHANNEL_GAP)
  const bottom = tops[tops.length - 1] + rowHeights[rowHeights.length - 1]

  const places = Object.fromEntries(ids.map((id) => [ id, {
    column: columns.get(id), row: rows.get(id),
    x: lefts[columns.get(id)], y: tops[rows.get(id)], width: widthOf(id), height: heightOf(id)
  } ]))

  const channelOf = (edge) => {
    if (backward.has(edge)) return MARGIN + (above.size - 1 - above.get(edge.target)) * CHANNEL_GAP
    if (skipping(edge)) return bottom + (below.get(edge.target) + 1) * CHANNEL_GAP
    return null
  }

  const heading = (edge) => channelOf(edge) ?? places[edge.target].y + places[edge.target].height / 2
  const leavingAt = new Map()
  outgoingOf(ids, edges).forEach((leaving) => [ ...leaving ].sort((a, b) => heading(a) - heading(b))
    .forEach((edge, at) => leavingAt.set(edge, (at + 1) / (leaving.length + 1))))

  const routed = (edge) => {
    const from = places[edge.source]
    const to = places[edge.target]
    const leaving = from.y + from.height * leavingAt.get(edge)
    const arriving = to.y + to.height / 2
    const turn = lefts[from.column] + columnWidths[from.column] + EXIT
    const channel = channelOf(edge)
    const start = [ [ from.x + from.width, leaving ], [ turn, leaving ] ]
    const end = [ [ to.x - COLUMN_GAP + EXIT, arriving ], [ to.x, arriving ] ]

    return { ...edge, points: channel === null ? [ ...start, [ turn, arriving ], end[1] ] : [ ...start, [ turn, channel ], [ end[0][0], channel ], ...end ] }
  }

  const last = columnWidths.length - 1

  return {
    places, links: edges.map(routed),
    width: lefts[last] + columnWidths[last] + EXIT + MARGIN / 2,
    height: bottom + below.size * CHANNEL_GAP + MARGIN
  }
}
