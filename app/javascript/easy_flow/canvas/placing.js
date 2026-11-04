export const fromToolbar = ({ nodes, edges }) => {
  const [ { source, target } ] = edges

  return { from: source, to: target }
}
