const filledIn = (value) => value !== undefined && value !== null && value !== ""

export const headerOf = (node, entry) =>
  [ node.type, ...Object.keys(entry?.fields || {}).filter((name) => filledIn(node.config[name])).map((name) => `${name}: ${node.config[name]}`) ].join(" · ")
