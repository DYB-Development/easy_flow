export const worded = (violation) => {
  const problem = violation.problem.replace(/_/g, " ")

  return violation.node ? `“${violation.node}” ${problem}` : problem
}

export const warned = (steps) => {
  const named = steps.map((step) => `“${step.name}”`).join(", ")

  if (steps.length === 1) return `${named} is not connected to the flow and will be removed. Remove it to go on, or cancel and connect it first.`

  return `${named} are not connected to the flow and will be removed. Remove them to go on, or cancel and connect them first.`
}
