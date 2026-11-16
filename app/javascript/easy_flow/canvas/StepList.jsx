const matching = (query) => (entry) => entry.label.toLowerCase().includes(query.trim().toLowerCase())

export const listed = (entries, groups, query = "") => {
  const grouped = Object.values(groups).flat()
  const sections = Object.entries(groups).map(([ heading, types ]) => ({
    heading,
    entries: types.map((type) => entries.find((entry) => entry.type === type)).filter(Boolean)
  }))

  return [ ...sections, { heading: null, entries: entries.filter((entry) => !grouped.includes(entry.type)) } ]
    .map((section) => ({ ...section, entries: section.entries.filter(matching(query)) }))
    .filter((section) => section.entries.length > 0)
}
