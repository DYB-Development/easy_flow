const filledIn = (value) => value !== undefined && value !== null && value !== "" && typeof value !== "object"

const settingName = (name, entry, hideStepTypeCodes) => (hideStepTypeCodes && entry.labels?.[name]) || name

export const headerOf = (node, entry, hideStepTypeCodes) => {
  const named = Object.keys(entry?.fields || {}).filter((name) => filledIn(node.config[name]))
    .map((name) => `${settingName(name, entry, hideStepTypeCodes)}: ${node.config[name]}`)

  return [ hideStepTypeCodes ? node.type_name || node.type : node.type, ...named ].join(" · ")
}

const ROOM_ABOVE = 10
const ROOM_BESIDE = 12

export const boxAround = (boxes, frame, surface) => {
  const left = Math.min(...boxes.map((box) => box.left)) - frame.left + surface.scrollLeft - ROOM_BESIDE
  const top = Math.min(...boxes.map((box) => box.top)) - frame.top + surface.scrollTop - ROOM_ABOVE
  const right = Math.max(...boxes.map((box) => box.left + box.width)) - frame.left + surface.scrollLeft + ROOM_BESIDE
  const bottom = Math.max(...boxes.map((box) => box.top + box.height)) - frame.top + surface.scrollTop + ROOM_ABOVE

  return { left, top, width: right - left, height: bottom - top }
}

const inside = ({ left, top, width, height }, point) =>
  point.x >= left && point.x <= left + width && point.y >= top && point.y <= top + height

export const boxAt = (boxes, point) => boxes.find((box) => inside(box.bounds, point))?.id || null
