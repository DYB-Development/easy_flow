import React from "react"
import Button from "keystone_ui-react/src/Button.jsx"

const round = { width: 24, height: 24, padding: 0, fontSize: 15, lineHeight: "15px" }

const Stepper = ({ label, title, idle, enabled, onUse }) => (
  <Button variant="secondary" size="sm" title={enabled ? title : idle} disabled={!enabled} onClick={onUse}
          style={{ opacity: enabled ? 1 : 0.4, cursor: enabled ? "pointer" : "default" }}>{label}</Button>
)

const Toolbar = ({ undoable, redoable, onAdd, onUndo, onRedo }) => (
  <div style={{ position: "absolute", top: 16, left: 16, zIndex: 5, display: "flex", gap: 8 }}>
    <Button variant="secondary" className="rounded-full" style={round} title="Add a step" onClick={onAdd}>+</Button>
    <Stepper label="↶ Undo" title="Undo the last change" idle="Nothing to undo" enabled={undoable} onUse={onUndo} />
    <Stepper label="↷ Redo" title="Redo the change you undid" idle="Nothing to redo" enabled={redoable} onUse={onRedo} />
  </div>
)

export default Toolbar
