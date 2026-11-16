import { useLayoutEffect, useState } from "react"
import { boxAround } from "./group"

export const anchor = (box, side, frame, surface) => {
  const left = box.left - frame.left + surface.scrollLeft
  const top = box.top - frame.top + surface.scrollTop

  if (side === "left") return { x: left, y: top + box.height / 2 }
  if (side === "right") return { x: left + box.width, y: top + box.height / 2 }
  if (side === "top") return { x: left + box.width / 2, y: top }
  return { x: left + box.width / 2, y: top + box.height }
}

export const shy = (point, side) => {
  if (side === "top") return { x: point.x, y: point.y - 3 }
  if (side === "left") return { x: point.x - 3, y: point.y }
  if (side === "right") return { x: point.x + 3, y: point.y }
  return { x: point.x, y: point.y + 3 }
}

export const drawn = (edge, a, b, lane, detour) => {
  const path = {
    straight: `M ${a.x} ${a.y} L ${b.x} ${b.y}`,
    turn: `M ${a.x} ${a.y} H ${b.x} V ${b.y}`,
    lane: `M ${a.x} ${a.y} V ${lane} H ${b.x} V ${b.y}`,
    detour: `M ${a.x} ${a.y} H ${detour} V ${b.y} H ${b.x}`
  }[edge.route]

  return {
    ...edge, path,
    midX: edge.route === "detour" ? detour : (a.x + b.x) / 2,
    midY: edge.route === "lane" ? lane : (a.y + b.y) / 2
  }
}

const useConnectors = (flow, surface, cards, watching) => {
  const [ links, setLinks ] = useState([])
  const [ extent, setExtent ] = useState({ width: "100%", height: "100%" })
  const [ boxes, setBoxes ] = useState([])

  useLayoutEffect(() => {
    const measure = () => {
      const frame = surface.current?.getBoundingClientRect()
      if (!frame) return

      setExtent({ width: surface.current.scrollWidth, height: surface.current.scrollHeight })

      setLinks(flow.edges.flatMap((edge) => {
        const fromBox = cards.current[edge.source]?.getBoundingClientRect()
        const toBox = cards.current[edge.target]?.getBoundingClientRect()
        if (!fromBox || !toBox) return []

        const a = anchor(fromBox, edge.leaves, frame, surface.current)
        const b = shy(anchor(toBox, edge.enters, frame, surface.current), edge.enters)
        const lane = (anchor(fromBox, "bottom", frame, surface.current).y + anchor(toBox, "top", frame, surface.current).y) / 2
        const detour = edge.leaves === "left" ? Math.min(a.x, b.x) - 28 : Math.max(a.x, b.x) + 28

        return [ drawn(edge, a, b, lane, detour) ]
      }))

      setBoxes(flow.nodes.filter((node) => node.holds && !node.loose && cards.current[node.id]).map((node) => {
        const header = cards.current[node.id]
        const headerBox = header.getBoundingClientRect()
        const held = node.holds.flatMap((id) => (cards.current[id] ? [ cards.current[id].getBoundingClientRect() ] : []))
        const measured = [ { left: headerBox.left, top: headerBox.top, width: Math.max(headerBox.width, header.scrollWidth), height: headerBox.height }, ...held ]

        return { id: node.id, bounds: boxAround(measured, frame, surface.current) }
      }))
    }

    measure()
    window.addEventListener("resize", measure)

    const watcher = new ResizeObserver(measure)
    if (surface.current) watcher.observe(surface.current)

    return () => {
      window.removeEventListener("resize", measure)
      watcher.disconnect()
    }
  }, watching)

  return { links, extent, boxes }
}

export default useConnectors
