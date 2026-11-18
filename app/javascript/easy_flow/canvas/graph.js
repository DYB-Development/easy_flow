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

export const layOut = (nodes, edges) => {
  const ids = nodes.map((node) => node.id)
  const backward = loopingBack(ids, edges)
  const forward = edges.filter((edge) => !backward.has(edge))
  const columns = columnsOf(ids, forward)
  const rows = rowsOf(ids, forward, columns)

  return { places: Object.fromEntries(ids.map((id) => [ id, { column: columns.get(id), row: rows.get(id) } ])) }
}
