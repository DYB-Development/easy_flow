export const worded = (violation) => {
  const problem = violation.problem.replace(/_/g, " ")

  return violation.node ? `“${violation.node}” ${problem}` : problem
}
