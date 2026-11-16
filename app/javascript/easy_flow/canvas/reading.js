const byPlace = (a, b) => a.row - b.row || a.column - b.column

export const readingOrder = (nodes) => {
  const placed = [ ...nodes ].sort(byPlace)
  const held = placed.filter((node) => nodes.some((group) => group.holds?.includes(node.id)))

  return placed.filter((node) => !held.includes(node))
    .flatMap((node) => [ node, ...held.filter((step) => node.holds?.includes(step.id)) ])
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

export const branchLine = (edge, nodes) =>
  [ edge.label, "→", nodes.find((node) => node.id === edge.target)?.label ].filter(Boolean).join(" ")
