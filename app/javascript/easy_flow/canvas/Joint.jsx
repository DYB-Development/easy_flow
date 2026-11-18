import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

const round = { width: 22, height: 22, padding: 0, fontSize: 14, lineHeight: "14px" }

const shownOnHover = "opacity-0 transition-opacity group-data-[over=true]:opacity-100"

const controls = { display: "flex", alignItems: "center", justifyContent: "flex-end", gap: 2, height: "100%" }

const Joint = ({ link, onInsert, onRemove, onDrop, alwaysShowInsertButtons, dragging, style }) => (
  <div data-joint={link?.id} className="group" style={style}
       onMouseEnter={(event) => { event.currentTarget.dataset.over = "true" }}
       onMouseLeave={(event) => { delete event.currentTarget.dataset.over }}
       onDragOver={(event) => { if (link && onDrop) { event.preventDefault(); event.dataTransfer.dropEffect = "move" } }}
       onDrop={(event) => { if (!link) return; event.preventDefault(); onDrop(link) }}>
    {link && onInsert && (
      <div style={controls}>
        <Button variant="secondary" title="Insert a step here" onClick={(event) => onInsert(link, event)}
                className={`rounded-full ${alwaysShowInsertButtons ? "opacity-100" : shownOnHover}`} style={dragging ? { ...round, opacity: 1 } : round}>+</Button>
        <Button variant="danger" title="Remove this connection" onClick={() => onRemove(link)} className={`rounded-full ${shownOnHover}`} style={round}>×</Button>
      </div>
    )}
  </div>
)

export default Joint
