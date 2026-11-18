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

export const layOut = (nodes, edges) => {
  const ids = nodes.map((node) => node.id)
  const columns = columnsOf(ids, edges)

  return { places: Object.fromEntries(ids.map((id) => [ id, { column: columns.get(id) } ])) }
}
