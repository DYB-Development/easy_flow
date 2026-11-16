import React from "react"

const card = { display: "block", minWidth: 118, boxSizing: "border-box", borderRadius: 6, padding: "8px 10px", textDecoration: "none" }

const named = { fontSize: 12, fontWeight: 500, lineHeight: 1.3 }

const RunCard = ({ node }) => (
  <div data-step={node.id} style={card}>
    <div className="font-mono text-gray-500 dark:text-gray-400" style={{ fontSize: 11 }}>{node.type}</div>
    <div style={named}>{node.label}{node.version && <span className="text-gray-500 dark:text-gray-400" style={{ fontWeight: 400, marginLeft: 4 }}>{node.version}</span>}</div>
    {node.status && <div style={{ fontSize: 11 }}>{node.status}</div>}
  </div>
)

export default RunCard
