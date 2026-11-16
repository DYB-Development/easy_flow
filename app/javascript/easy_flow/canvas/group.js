export const headerOf = (node, entry) =>
  [ node.type, ...Object.keys(entry?.fields || {}).map((name) => `${name}: ${node.config[name]}`) ].join(" · ")
