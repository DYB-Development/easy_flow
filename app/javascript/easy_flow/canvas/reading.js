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
  const ordered = readingOrder(nodes)
  const held = (step) => ordered.some((group) => group.holds?.includes(step.id))

  return ordered.filter((node) => !held(node)).reduce((blocks, node) => {
    if (node.holds) return [ ...blocks, { group: node, steps: ordered.filter((step) => node.holds.includes(step.id)) } ]

    const last = blocks[blocks.length - 1]
    if (last && !last.group) return [ ...blocks.slice(0, -1), { steps: [ ...last.steps, node ] } ]
    return [ ...blocks, { steps: [ node ] } ]
  }, [])
}

const nextAfter = (ordered, node) => ordered[ordered.findIndex((step) => step.id === node.id) + 1]?.id

export const branchesOf = (node, edges, nodes) => {
  const next = nextAfter(readingOrder(nodes), node)

  return edges.filter((edge) => edge.source === node.id && (edge.label || edge.target !== next))
}

const nameOf = (step) => (step?.placeholder ? "nowhere yet" : step?.label)

export const branchLine = (edge, nodes) =>
  [ edge.label, "→", nameOf(nodes.find((node) => node.id === edge.target)) ].filter(Boolean).join(" ")

export const joining = (edges, before, after) => edges.find((edge) => edge.source === before.id && edge.target === after.id)

export const branchLinesOf = (steps, edges, nodes) => {
  const ordered = readingOrder(steps)
  const next = new Map(ordered.map((step, at) => [ step.id, ordered[at + 1]?.id ]))
  const names = new Map(nodes.map((node) => [ node.id, nameOf(node) ]))
  const lines = Object.fromEntries(steps.map((step) => [ step.id, [] ]))

  edges.filter((edge) => lines[edge.source] && (edge.label || edge.target !== next.get(edge.source)))
    .forEach((edge) => lines[edge.source].push([ edge.label, "→", names.get(edge.target) ].filter(Boolean).join(" ")))

  return lines
}
