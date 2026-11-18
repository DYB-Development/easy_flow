import React, { useLayoutEffect, useMemo, useRef, useState } from "react"
import Joint from "./Joint"
import { EXIT, layOut } from "./graph"

const stack = { display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 14, padding: "64px 0 0" }

const label = {
  position: "absolute", zIndex: 3, maxWidth: EXIT - 10, fontSize: 11, lineHeight: "14px", pointerEvents: "none",
  overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap"
}

const pathOf =(points) => points.map(([ x, y ], at) => `${at === 0 ? "M" : "L"} ${x} ${y}`).join(" ")

const measuredHeights = (slots) =>
  Object.fromEntries(Object.entries(slots).filter(([ , slot ]) => slot?.firstElementChild).map(([ id, slot ]) => [ id, slot.firstElementChild.offsetHeight ]))

const changed = (before, after) => Object.keys(after).some((id) => before[id] !== after[id])

const Graph = ({ nodes, edges, draw, joints }) => {
  const [ heights, setHeights ] = useState({})
  const slots = useRef({})
  const graph = useMemo(() => layOut(nodes, edges, { heights }), [ nodes, edges, heights ])

  useLayoutEffect(() => {
    const measured = measuredHeights(slots.current)
    if (changed(heights, measured)) setHeights({ ...heights, ...measured })
  })

  const slotted = (id) => (slot) => { slots.current[id] = slot }

  return (
    <div data-flow-graph style={{ position: "relative", flex: "none", width: graph.width, height: graph.height }}>
      <svg width={graph.width} height={graph.height} style={{ position: "absolute", top: 0, left: 0, pointerEvents: "none" }}>
        <defs>
          <marker id="easy_flow-graph-arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto">
            <path d="M 0 0 L 10 5 L 0 10 z" className="fill-gray-400 dark:fill-zinc-500" />
          </marker>
        </defs>
        {graph.links.map((link) => (
          <path key={link.id} data-link={link.id} d={pathOf(link.points)} fill="none" strokeWidth="1.5"
                className="stroke-gray-400 dark:stroke-zinc-500" markerEnd="url(#easy_flow-graph-arrow)" />
        ))}
      </svg>

      {nodes.map((node) => {
        const place = graph.places[node.id]
        if (node.holds) {
          return (
            <div key={node.id} ref={slotted(node.id)} data-group-box={node.id}
                 className="border border-dashed border-gray-400 bg-white/60 dark:border-zinc-600 dark:bg-zinc-900/60"
                 style={{ position: "absolute", left: place.x, top: place.y, width: place.width, height: place.height, boxSizing: "border-box", borderRadius: 8 }}>
              <div style={{ padding: "4px 10px" }}>{draw(node)}</div>
            </div>
          )
        }

        return (
          <div key={node.id} ref={slotted(node.id)} style={{ position: "absolute", left: place.x, top: place.y, width: place.width, zIndex: 2 }}>
            {draw(node)}
          </div>
        )
      })}

      {graph.links.filter((link) => link.label).map((link) => (
        <div key={`${link.id}-label`} data-link-label={link.id} title={link.label} className="text-gray-500 dark:text-gray-400"
             style={{ ...label, left: link.points[0][0] + 6, top: link.points[0][1] - 16 }}>{link.label}</div>
      ))}

      {joints.onInsert && graph.links.filter((link) => !link.placeholder).map((link) => (
        <Joint key={link.id} link={link} {...joints}
               style={{ position: "absolute", left: link.points[0][0], top: link.points[0][1] - 12, width: EXIT + 14, height: 24, zIndex: 3 }} />
      ))}
    </div>
  )
}

const LeftToRight = ({ nodes, edges, draw, joints, children, style }) => (
  <div data-flow-rows style={{ ...stack, ...style }}>
    {children}
    <Graph nodes={nodes} edges={edges} draw={draw} joints={joints} />
  </div>
)

export default LeftToRight
