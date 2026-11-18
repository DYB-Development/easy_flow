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

const endOf = (starts, sizes) => (starts.length > 0 ? starts[starts.length - 1] + sizes[sizes.length - 1] : 0)

const arrange = (ids, edges, sizeOf, room) => {
  const backward = loopingBack(ids, edges)
  const forward = edges.filter((edge) => !backward.has(edge))
  const columns = columnsOf(ids, forward)
  const rows = rowsOf(ids, forward, columns)

  const columnWidths = []
  const rowHeights = []
  ids.forEach((id) => {
    columnWidths[columns.get(id)] = Math.max(columnWidths[columns.get(id)] || 0, sizeOf(id).width)
    rowHeights[rows.get(id)] = Math.max(rowHeights[rows.get(id)] || 0, sizeOf(id).height)
  })
  const skipping = (edge) => columns.get(edge.target) > columns.get(edge.source) + 1
  const channelsOf = (taken) => {
    const channels = new Map()
    taken.forEach((edge) => { if (!channels.has(edge.target)) channels.set(edge.target, channels.size) })
    return channels
  }
  const above = channelsOf(edges.filter((edge) => backward.has(edge)))
  const below = channelsOf(forward.filter(skipping))

  const lefts = startsOf(columnWidths, COLUMN_GAP, room.left)
  const tops = startsOf(rowHeights, ROW_GAP, room.top + above.size * CHANNEL_GAP)
  const bottom = endOf(tops, rowHeights)

  const places = Object.fromEntries(ids.map((id) => [ id, {
    column: columns.get(id), row: rows.get(id),
    x: lefts[columns.get(id)], y: tops[rows.get(id)], width: sizeOf(id).width, height: sizeOf(id).height
  } ]))

  const channelOf = (edge) => {
    if (backward.has(edge)) return room.top + (above.size - 1 - above.get(edge.target)) * CHANNEL_GAP
    if (skipping(edge)) return bottom + (below.get(edge.target) + 1) * CHANNEL_GAP
    return null
  }

  const arrivingAt = (id) => places[id].y + (sizeOf(id).arrives ?? places[id].height / 2)
  const heading = (edge) => channelOf(edge) ?? arrivingAt(edge.target)
  const leavingAt = new Map()
  outgoingOf(ids, edges).forEach((leaving) => [ ...leaving ].sort((a, b) => heading(a) - heading(b))
    .forEach((edge, at) => leavingAt.set(edge, (at + 1) / (leaving.length + 1))))

  const routed = (edge) => {
    const from = places[edge.source]
    const to = places[edge.target]
    const leaving = from.y + from.height * leavingAt.get(edge)
    const arriving = arrivingAt(edge.target)
    const turn = lefts[from.column] + columnWidths[from.column] + EXIT
    const channel = channelOf(edge)
    const start = [ [ from.x + from.width, leaving ], [ turn, leaving ] ]
    const end = [ [ to.x - COLUMN_GAP + EXIT, arriving ], [ to.x, arriving ] ]

    return { ...edge.drawn, points: channel === null ? [ ...start, [ turn, arriving ], end[1] ] : [ ...start, [ turn, channel ], [ end[0][0], channel ], ...end ] }
  }

  const links = edges.map(routed)
  const corners = [ ...Object.values(places).map((card) => [ card.x + card.width, card.y + card.height ]), ...links.flatMap((each) => each.points) ]
  const farthest = corners.reduce(([ right, low ], [ x, y ]) => [ Math.max(right, x), Math.max(low, y) ], [ 0, 0 ])

  return { places, links, width: farthest[0] + room.right, height: farthest[1] + room.bottom }
}

const ENTRY = "\u0000entry"
const HEADER_HEIGHT = 24
const OUTSIDE = { left: COLUMN_GAP - EXIT + MARGIN / 2, top: MARGIN, right: MARGIN / 2, bottom: MARGIN }
const INSIDE = { left: 0, top: 8, right: 16, bottom: 12 }

export const layOut = (nodes, given, { heights = {} } = {}) => {
  const drawn = new Set(nodes.map((node) => node.id))
  const holders = new Map(nodes.flatMap((group) => (group.holds || []).filter((id) => drawn.has(id)).map((id) => [ id, group.id ])))
  const levels = new Map([ [ null, { ids: [], edges: [] } ] ])
  nodes.filter((node) => node.holds).forEach((group) => levels.set(group.id, { ids: [ ENTRY ], edges: [] }))
  nodes.forEach((node) => levels.get(holders.get(node.id) ?? null).ids.push(node.id))

  given.filter((edge) => drawn.has(edge.source) && drawn.has(edge.target)).forEach((edge) => {
    const inside = holders.get(edge.target)
    if (inside && inside === edge.source) levels.get(inside).edges.push({ source: ENTRY, target: edge.target, drawn: edge })
    else if (inside && inside === holders.get(edge.source)) levels.get(inside).edges.push({ source: edge.source, target: edge.target, drawn: edge })
    else levels.get(null).edges.push({ source: holders.get(edge.source) ?? edge.source, target: inside ?? edge.target, drawn: edge })
  })

  const cardSize = (id) => ({ width: CARD_WIDTH, height: heights[id] || CARD_HEIGHT })
  const insides = new Map([ ...levels ].filter(([ group ]) => group).map(([ group, level ]) =>
    [ group, arrange(level.ids, level.edges, (id) => (id === ENTRY ? { width: 0, height: CARD_HEIGHT } : cardSize(id)), INSIDE) ]))
  const headerOf = (id) => heights[id] || HEADER_HEIGHT
  const sizeOf = (id) => {
    const inside = insides.get(id)
    if (!inside) return cardSize(id)
    return { width: inside.width, height: headerOf(id) + inside.height, arrives: headerOf(id) + inside.places[ENTRY].y + CARD_HEIGHT / 2 }
  }

  const outside = arrange(levels.get(null).ids, levels.get(null).edges, sizeOf, OUTSIDE)
  const places = { ...outside.places }
  const links = [ ...outside.links ]
  insides.forEach((inside, group) => {
    const box = outside.places[group]
    const [ x, y ] = [ box.x, box.y + headerOf(group) ]
    Object.entries(inside.places).filter(([ id ]) => id !== ENTRY)
      .forEach(([ id, place ]) => { places[id] = { ...place, x: place.x + x, y: place.y + y } })
    inside.links.forEach((each) => links.push({ ...each, points: each.points.map(([ px, py ]) => [ px + x, py + y ]) }))
  })

  return { places, links, width: outside.width, height: outside.height }
}
