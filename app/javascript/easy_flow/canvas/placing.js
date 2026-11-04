export const unconnected = { where: "Goes beside the flow, not connected" }

export const fromToolbar = ({ nodes, edges }) => {
  const ends = nodes.filter((node) => node.ends_here).map((node) => node.id)
  const intoEnd = edges.filter((edge) => ends.includes(edge.target))
  if (intoEnd.length !== 1) return unconnected

  const [ { source, target } ] = intoEnd

  const named = (id) => nodes.find((node) => node.id === id).label

  return { from: source, to: target, where: `Goes between ${named(source)} and ${named(target)}` }
}
