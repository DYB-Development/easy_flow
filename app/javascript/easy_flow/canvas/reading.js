const byPlace = (a, b) => a.row - b.row || a.column - b.column

export const readingOrder = (nodes) => {
  const placed = [ ...nodes ].sort(byPlace)
  const held = placed.filter((node) => nodes.some((group) => group.holds?.includes(node.id)))

  return placed.filter((node) => !held.includes(node))
    .flatMap((node) => [ node, ...held.filter((step) => node.holds?.includes(step.id)) ])
}
