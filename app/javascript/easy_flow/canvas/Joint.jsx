import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

const round = { width: 24, height: 24, padding: 0, fontSize: 15, lineHeight: "15px" }

const shownOnHover = "opacity-0 transition-opacity group-data-[over=true]:opacity-100"

const Joint = ({ link, onInsert, onRemove, onDrop, alwaysShowInsertButtons }) => (
  <div data-joint={link?.id} className="group relative h-7 w-full sm:h-auto sm:w-7 sm:self-stretch"
       onMouseEnter={(event) => { event.currentTarget.dataset.over = "true" }}
       onMouseLeave={(event) => { delete event.currentTarget.dataset.over }}
       onDragOver={(event) => { if (link) { event.preventDefault(); event.dataTransfer.dropEffect = "move" } }}
       onDrop={(event) => { if (!link) return; event.preventDefault(); onDrop(link) }}>
    {link && <div className="absolute left-1/2 top-0 h-full w-px bg-gray-400 sm:left-0 sm:top-1/2 sm:h-px sm:w-full dark:bg-zinc-500" />}
    {link && (
      <div className="absolute inset-0 flex items-center justify-center gap-1 sm:flex-col" style={{ zIndex: 4 }}>
        <Button variant="secondary" title="Insert a step here" onClick={(event) => onInsert(link, event)}
                className={`rounded-full ${alwaysShowInsertButtons ? "opacity-100" : shownOnHover}`} style={round}>+</Button>
        <Button variant="danger" title="Remove this connection" onClick={() => onRemove(link)} className={`rounded-full ${shownOnHover}`} style={round}>×</Button>
      </div>
    )}
  </div>
)

export default Joint
