import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"
import Port from "./Port"
import { CARD } from "./styles"

const card = { width: CARD, boxSizing: "border-box", borderRadius: 8 }

const compactCard = { minWidth: 120, boxSizing: "border-box", borderRadius: 6 }

const bookendCard = { padding: "8px 14px", textAlign: "center", fontWeight: 600, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }

const named = { fontWeight: 600, lineHeight: 1.3 }

const compactName = { fontSize: 12, fontWeight: 500, lineHeight: 1.3 }

const edge = (target, troubled, selected) => {
  const lift = selected ? "ring-4 ring-accent-600/15" : "shadow-sm"
  if (target || (selected && !troubled)) return `border-accent-600 ${lift}`
  if (troubled) return `border-red-600 ${lift}`
  return "border-gray-300 shadow-sm dark:border-zinc-700"
}

const headingOf = (node, hideStepTypeCodes) =>
  hideStepTypeCodes && node.label === node.id ? node.type_name || node.label : node.label

const markedOf = (node, heading) => [ heading, node.ends_here && node.mark ].filter(Boolean).join(" · ")

const typeLineOf = (node, heading, hideStepTypeCodes) => {
  if (!hideStepTypeCodes) return node.type
  return heading === node.type_name ? null : node.type_name
}

const StepCard = ({ node, selected, armed, connecting, onSelect, onOpen, onArm, onDragEnd, onDragStart, hideStepTypeCodes, compact = false, typeAbove = compact }) => {
  const bookend = node.begins_here || node.ends_here
  const pinned = node.begins_here
  const ports = node.ends_here ? [] : node.ports
  const target = connecting && !pinned
  const heading = headingOf(node, hideStepTypeCodes)
  const typeLine = typeLineOf(node, heading, hideStepTypeCodes)

  return (
    <div ref={node.ref}
         data-step={node.id}
         draggable={!pinned}
         onDragStart={(event) => { event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", node.id); onDragStart() }}
         onDragEnd={onDragEnd}
         onClick={node.opens && !connecting ? () => onOpen(node.opens) : onSelect}
         className={`bg-white ${compact && !selected ? "border" : "border-2"} dark:bg-zinc-900 ${edge(target, node.violations.length > 0, selected)}`}
         style={{
           ...(compact ? compactCard : card),
           padding: bookend ? 0 : compact ? "8px 10px" : "12px 14px",
           cursor: pinned ? "default" : connecting ? "crosshair" : "grab"
         }}>
      {!bookend && typeAbove && typeLine && <div className="font-mono text-gray-500 dark:text-gray-400" style={{ fontSize: 11 }}>{typeLine}</div>}
      {bookend && <div className="text-gray-500 dark:text-gray-400" style={bookendCard}>{markedOf(node, heading)}</div>}
      {!bookend && <div style={compact ? compactName : named}>{heading}</div>}
      {node.violations.length > 0 && <div data-error-count className="text-red-600 dark:text-red-400" style={{ fontSize: 10 }}>{`${node.violations.length} error${node.violations.length === 1 ? "" : "s"}`}</div>}
      {!bookend && node.summary && node.violations.length === 0 && <div className={selected ? "text-accent-600 dark:text-accent-400" : "text-gray-500 dark:text-gray-400"} style={{ fontSize: 10 }}>{node.summary}</div>}
      {!bookend && !typeAbove && typeLine && <div className="text-gray-500 dark:text-gray-400" style={{ fontSize: 11, marginTop: 2 }}>{typeLine}</div>}
      {node.picture_url && <div className="text-accent-600 dark:text-accent-400" style={{ fontSize: 11, marginTop: 2 }}>Has a picture</div>}
      {node.starts_a_flow && <div className="text-accent-600 dark:text-accent-400" style={{ fontSize: 11, marginTop: 2 }}>Runs a flow</div>}
      {node.opens && <Button variant="secondary" size="sm" className="mt-2" onClick={(event) => { event.stopPropagation(); onSelect() }}>Settings</Button>}
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
