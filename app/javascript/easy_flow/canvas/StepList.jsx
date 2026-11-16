export const listed = (entries, groups) => {
  const grouped = Object.values(groups).flat()
  const sections = Object.entries(groups).map(([ heading, types ]) => ({
    heading,
    entries: types.map((type) => entries.find((entry) => entry.type === type)).filter(Boolean)
  }))

  return [ ...sections, { heading: null, entries: entries.filter((entry) => !grouped.includes(entry.type)) } ]
    .filter((section) => section.entries.length > 0)
}
