export const nextId = (type, taken) => {
  const used = new Set(taken)
  let candidate = type
  let suffix = 2
  while (used.has(candidate)) candidate = `${type}_${suffix++}`
  return candidate
}
