import React from "react"
import Port from "./Port"
import { CARD } from "./styles"

const card = { width: CARD, boxSizing: "border-box", borderRadius: 8 }

const bookendCard = { padding: "8px 14px", textAlign: "center", fontWeight: 600 }

const named = { fontWeight: 600, lineHeight: 1.3 }

const edge = (target, troubled, selected) => {
  const lift = selected ? "ring-4 ring-accent-600/15" : "shadow-sm"
  if (target || (selected && !troubled)) return `border-accent-600 ${lift}`
  if (troubled) return `border-red-600 ${lift}`
  return "border-gray-300 shadow-sm dark:border-zinc-700"
}

const StepCard = ({ node, selected, armed, connecting, onSelect, onArm, onDragEnd, onDragStart }) => {
  const bookend = node.begins_here || node.ends_here
  const pinned = node.begins_here
  const ports = node.ends_here ? [] : node.ports
  const target = connecting && !pinned

  return (
    <div ref={node.ref}
         data-step={node.id}
         draggable={!pinned}
         onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
         onDragEnd={onDragEnd}
         onClick={onSelect}
         className={`bg-white border-2 dark:bg-zinc-900 ${edge(target, node.violations.length > 0, selected)}`}
         style={{
           ...card,
           padding: bookend ? 0 : "12px 14px",
           cursor: pinned ? "default" : connecting ? "crosshair" : "grab"
         }}>
      {bookend && <div className="text-gray-500 dark:text-gray-400" style={bookendCard}>{node.label}</div>}
      {!bookend && <div style={named}>{node.label}</div>}
      {!bookend && <div className="text-gray-500 dark:text-gray-400" style={{ fontSize: 11, marginTop: 2 }}>{node.type}</div>}
      {node.violations.map((violation) => (
        <div key={violation.problem + violation.detail} className="text-red-600 dark:text-red-400" style={{ fontSize: 11, padding: "0 14px 6px" }}>
          {violation.problem.replace(/_/g, " ")}{violation.detail ? `: ${violation.detail}` : ""}
        </div>
      ))}
      {ports.length > 0 && (
        <div style={{ padding: node.begins_here ? "0 14px 8px" : "10px 0 0" }}>
          {ports.map((port) => (
            <Port key={port} name={port} connected={node.connected.includes(port)}
                  connecting={connecting} armed={armed === port} onArm={(event) => onArm(port, event)} />
          ))}
        </div>
      )}
    </div>
  )
}

export default StepCard
