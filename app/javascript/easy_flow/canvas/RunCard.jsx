import React from "react"

const card = { display: "block", minWidth: 118, boxSizing: "border-box", borderRadius: 6, padding: "8px 10px", textDecoration: "none" }

const named = { fontSize: 12, fontWeight: 500, lineHeight: 1.3 }

const bookendName = { ...named, textAlign: "center", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }

const STATES = {
  done: "border-green-600 bg-green-50 dark:border-green-500 dark:bg-green-950",
  paused: "border-amber-500 bg-amber-50 dark:border-amber-400 dark:bg-amber-950",
  pending: "border-gray-300 bg-white text-gray-500 dark:border-zinc-700 dark:bg-zinc-900 dark:text-gray-400",
  failed: "border-red-600 bg-red-50 dark:border-red-500 dark:bg-red-950"
}

const STATUS_LINES = {
  done: "text-green-700 dark:text-green-400",
  paused: "text-amber-800 dark:text-amber-300",
  pending: "text-gray-500 dark:text-gray-400",
  failed: "text-red-700 dark:text-red-400"
}

const markedOf = (node) => [ node.label, node.ends_here && node.mark ].filter(Boolean).join(" · ")

const marked = "ring-2 ring-accent-600 ring-offset-2 dark:ring-offset-zinc-950"

const RunCard = ({ node, selected = false }) => {
  const Card = node.address ? "a" : "div"
  const bookend = node.begins_here || node.ends_here

  return (
    <Card data-step={node.id} href={node.address || undefined} className={`${node.state === "paused" ? "border-2" : "border"} ${STATES[node.state] || STATES.pending}${selected ? ` ${marked}` : ""}`} style={card}>
      {!bookend && <div className="font-mono text-gray-500 dark:text-gray-400" style={{ fontSize: 11 }}>{node.type}</div>}
      <div style={bookend ? bookendName : named}>{markedOf(node)}{node.version && <span className="text-gray-500 dark:text-gray-400" style={{ fontWeight: 400, marginLeft: 4 }}>{node.version}</span>}</div>
      {node.status && <div className={STATUS_LINES[node.state] || STATUS_LINES.pending} style={{ fontSize: 11 }}>{node.status}</div>}
    </Card>
  )
}

export default RunCard
