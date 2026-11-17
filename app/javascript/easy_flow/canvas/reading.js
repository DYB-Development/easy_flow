const byPlace = (a, b) => a.row - b.row || a.column - b.column

const holdersOf = (nodes) => new Map(nodes.flatMap((group) => (group.holds || []).map((id) => [ id, group.id ])))

export const readingOrder = (nodes) => {
  const placed = [ ...nodes ].sort(byPlace)
  const holders = holdersOf(nodes)
  const held = new Map(nodes.filter((node) => node.holds).map((group) => [ group.id, [] ]))
  placed.filter((node) => holders.has(node.id)).forEach((node) => held.get(holders.get(node.id)).push(node))

  return placed.filter((node) => !holders.has(node.id)).flatMap((node) => [ node, ...(held.get(node.id) || []) ])
}

export const blocksOf = (nodes) => {
  const holders = holdersOf(nodes)
  const ordered = readingOrder(nodes)
  const blocks = []
  const boxes = new Map()

  ordered.filter((node) => !holders.has(node.id)).forEach((node) => {
    const last = blocks[blocks.length - 1]
    if (node.holds) boxes.set(node.id, blocks[blocks.push({ group: node, steps: [] }) - 1])
    else if (last && !last.group) last.steps.push(node)
    else blocks.push({ steps: [ node ] })
  })
  ordered.filter((node) => holders.has(node.id)).forEach((node) => boxes.get(holders.get(node.id))?.steps.push(node))

  return blocks
}

const nameOf = (step) => (step?.placeholder ? "nowhere yet" : step?.label)

const joins = new WeakMap()

const joinsOf = (edges) => {
  if (!joins.has(edges)) joins.set(edges, new Map([ ...edges ].reverse().map((edge) => [ `${edge.source}\n${edge.target}`, edge ])))
  return joins.get(edges)
}

export const joining = (edges, before, after) => joinsOf(edges).get(`${before.id}\n${after.id}`)

export const branchLinesOf = (steps, edges, nodes) => {
  const ordered = readingOrder(steps)
  const next = new Map(ordered.map((step, at) => [ step.id, ordered[at + 1]?.id ]))
  const names = new Map(nodes.map((node) => [ node.id, nameOf(node) ]))
  const lines = Object.fromEntries(steps.map((step) => [ step.id, [] ]))

  edges.filter((edge) => lines[edge.source] && (edge.label || edge.target !== next.get(edge.source)))
    .forEach((edge) => lines[edge.source].push([ edge.label, "→", names.get(edge.target) ].filter(Boolean).join(" ")))

  return lines
}
