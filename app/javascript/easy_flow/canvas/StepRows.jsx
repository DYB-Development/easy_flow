import React from "react"
import Joint from "./Joint"
import { layOut } from "./graph"

const stack = { display: "flex", flexDirection: "column", gap: 14, padding: "64px 0 0" }

const box = { display: "flex", flexDirection: "column", gap: 10, padding: "8px 10px", borderRadius: 8 }

const connection = { display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8, minHeight: 26, paddingLeft: 12, fontSize: 11 }

const byPlace = (places) => (a, b) => places[a.id].column - places[b.id].column || places[a.id].row - places[b.id].row

const nameOf = (node) => (node?.placeholder ? "nowhere yet" : node?.label)

const Row = ({ node, leaving, named, draw, joints }) => (
  <div data-step-row={node.id}>
    {draw(node)}
    {leaving.map((link) => (
      <Joint key={link.id} link={link} {...joints} alwaysShowInsertButtons shown
             className="border-l border-gray-300 text-gray-500 dark:border-zinc-600 dark:text-gray-400" style={connection}>
        <span>{[ link.label, "→", named.get(link.target) ].filter(Boolean).join(" ")}</span>
      </Joint>
    ))}
  </div>
)

const StepRows = ({ nodes, edges, draw, joints, children, style }) => {
  const { places } = layOut(nodes, edges)
  const named = new Map(nodes.map((node) => [ node.id, nameOf(node) ]))
  const leaving = new Map(nodes.map((node) => [ node.id, [] ]))
  edges.forEach((edge) => { if (leaving.has(edge.source) && named.has(edge.target)) leaving.get(edge.source).push(edge) })
  const holders = new Map(nodes.flatMap((group) => (group.holds || []).map((id) => [ id, group.id ])))
  const ordered = [ ...nodes ].sort(byPlace(places))
  const inside = new Map()
  ordered.filter((node) => holders.has(node.id)).forEach((node) => {
    if (!inside.has(holders.get(node.id))) inside.set(holders.get(node.id), [])
    inside.get(holders.get(node.id)).push(node)
  })
  const row = (node) => <Row key={node.id} node={node} leaving={leaving.get(node.id)} named={named} draw={draw} joints={joints} />

  return (
    <div data-flow-rows style={{ ...stack, ...style }}>
      {children}
      {ordered.filter((node) => !holders.has(node.id)).map((node) => (node.holds
        ? (
          <div key={node.id} data-group-box={node.id} className="border border-dashed border-gray-400 bg-white/60 dark:border-zinc-600 dark:bg-zinc-900/60" style={box}>
            {row(node)}
            {(inside.get(node.id) || []).map(row)}
          </div>
        )
        : row(node)))}
    </div>
  )
}

export default StepRows
