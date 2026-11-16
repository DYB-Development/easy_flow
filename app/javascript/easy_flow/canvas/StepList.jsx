export const listed = (entries, groups) =>
  Object.entries(groups).map(([ heading, types ]) => ({
    heading,
    entries: types.map((type) => entries.find((entry) => entry.type === type)).filter(Boolean)
  }))
