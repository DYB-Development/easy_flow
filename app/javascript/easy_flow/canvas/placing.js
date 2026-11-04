export const fromToolbar = ({ nodes, edges }) => {
  if (edges.length !== 1) return {}

  const [ { source, target } ] = edges

  return { from: source, to: target }
}
