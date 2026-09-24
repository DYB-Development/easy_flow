import React from "react"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Button from "keystone_ui-react/src/Button.jsx"

const TypePicker = ({ entries, at, onPick, onConnect, onDismiss }) => (
  <Panel className="shadow-lg" style={{ position: "absolute", zIndex: 9, top: at.y, left: at.x, width: 210, padding: 8, borderRadius: 8 }}>
    <p className="text-gray-500 dark:text-gray-400" style={{ margin: "0 0 6px", fontSize: 11 }}>Add a step</p>
    {entries.map((entry) => (
      <Button key={entry.type} variant="secondary" size="sm" className="w-full mb-1.5 flex-col" onClick={() => onPick(entry)}>
        {entry.label}
        <span className="opacity-75" style={{ display: "block", fontSize: 11 }}>{entry.type}</span>
      </Button>
    ))}
    {onConnect && (
      <Button variant="secondary" size="sm" className="w-full mb-1.5" onClick={onConnect}>Connect to a step already here</Button>
    )}
    <Button variant="secondary" size="sm" className="w-full" onClick={onDismiss}>Cancel</Button>
  </Panel>
)

export default TypePicker
