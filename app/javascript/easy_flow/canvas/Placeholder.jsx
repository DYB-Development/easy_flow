import React from "react"
import { CARD } from "./styles"

const waiting = {
  width: CARD, boxSizing: "border-box", padding: "10px 14px", borderRadius: 8, textAlign: "center", fontSize: 12, cursor: "pointer"
}

const open = "border-2 border-dashed border-amber-500 bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300"
const receiving = "border-2 border-dashed border-accent-600 bg-accent-50 text-accent-800 dark:bg-accent-950 dark:text-accent-200"

const Placeholder = ({ node, dragging, onFill, onDrop }) => (
  <div ref={node.ref} data-placeholder={node.id}
       title={`Choose the step “${node.label}” should lead to`}
       onClick={onFill}
       onDragOver={(event) => { if (dragging) { event.preventDefault(); event.dataTransfer.dropEffect = "move" } }}
       onDrop={(event) => { event.preventDefault(); onDrop() }}
       className={dragging ? receiving : open}
       style={waiting}>
    <div style={{ fontWeight: 600 }}>{node.label}</div>
    <div style={{ fontSize: 11 }}>{dragging ? "drop a step here" : "leads nowhere yet — click to choose"}</div>
  </div>
)

export default Placeholder
