export const fromToolbar = ({ nodes, edges }) => {
  const ends = nodes.filter((node) => node.ends_here).map((node) => node.id)
  const intoEnd = edges.filter((edge) => ends.includes(edge.target))
  if (intoEnd.length !== 1) return {}

  const [ { source, target } ] = intoEnd

  return { from: source, to: target }
}
