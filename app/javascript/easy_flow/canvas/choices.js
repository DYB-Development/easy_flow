export const toggled = (chosen, choice) =>
  chosen.includes(choice) ? chosen.filter((each) => each !== choice) : [ ...chosen, choice ]

export const offeredTo = (node, entry) => ({ ...(entry?.choices || {}), ...(node?.choices || {}) })
