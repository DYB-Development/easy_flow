import React from "react"

const card = { display: "block", minWidth: 118, boxSizing: "border-box", borderRadius: 6, padding: "8px 10px", textDecoration: "none" }

const named = { fontSize: 12, fontWeight: 500, lineHeight: 1.3 }

const STATES = {
  done: "border-green-600 bg-green-50 dark:border-green-500 dark:bg-green-950",
  paused: "border-amber-500 bg-amber-50 dark:border-amber-400 dark:bg-amber-950",
  pending: "border-gray-300 bg-white dark:border-zinc-700 dark:bg-zinc-900",
  failed: "border-red-600 bg-red-50 dark:border-red-500 dark:bg-red-950"
}

const RunCard = ({ node }) => (
  <div data-step={node.id} className={`border ${STATES[node.state] || STATES.pending}`} style={card}>
    <div className="font-mono text-gray-500 dark:text-gray-400" style={{ fontSize: 11 }}>{node.type}</div>
    <div style={named}>{node.label}{node.version && <span className="text-gray-500 dark:text-gray-400" style={{ fontWeight: 400, marginLeft: 4 }}>{node.version}</span>}</div>
    {node.status && <div style={{ fontSize: 11 }}>{node.status}</div>}
  </div>
)

export default RunCard
