const filledIn = (value) => value !== undefined && value !== null && value !== "" && typeof value !== "object"

const settingName = (name, entry, hideStepTypeCodes) => (hideStepTypeCodes && entry.labels?.[name]) || name

export const headerOf = (node, entry, hideStepTypeCodes) => {
  const named = Object.keys(entry?.fields || {}).filter((name) => filledIn(node.config[name]))
    .map((name) => `${settingName(name, entry, hideStepTypeCodes)}: ${node.config[name]}`)

  return [ hideStepTypeCodes ? node.type_name || node.type : node.type, ...named ].join(" · ")
}
