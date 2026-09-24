import React, { useEffect, useState } from "react"
import Control from "./Control"
import Records from "./Records"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const panel = { width: 280, padding: 20, overflowY: "auto" }

const Inspector = ({ node, fields, holds, labels, recordLabels, choices, onSave, onDelete, onClose }) => {
  const [ draft, setDraft ] = useState(node.config)
  useEffect(() => setDraft(node.config), [ node.id, node.config ])

  const settle = (next) => {
    setDraft(next)
    if (JSON.stringify(next) !== JSON.stringify(node.config)) onSave(next)
  }

  return (
    <Panel as="aside" style={panel} data-inspector>
      <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8 }}>
        <h2 style={{ fontWeight: 600, marginBottom: 2 }}>{node.label}</h2>
        <button title="Close" onClick={onClose} className="text-gray-500 dark:text-gray-400"
                style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1 }}>×</button>
      </div>
      <p className="text-gray-500 dark:text-gray-400" style={{ fontSize: 11, marginBottom: 16 }}>{node.id} · {node.type}</p>
      {Object.entries(fields).map(([ name, type ]) => (
        <Label key={name}>
          <span style={{ display: "block", marginBottom: 3 }}>{labels[name] || name}</span>
          {type === "list"
            ? <Records holds={holds[name] || {}} labels={recordLabels[name] || {}} rows={draft[name]}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })} />
            : <Control type={type} value={draft[name]} choices={choices[name]}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })} />}
        </Label>
      ))}
      <Button variant="danger" size="sm" className="w-full" onClick={onDelete}>Delete step</Button>
    </Panel>
  )
}

export default Inspector
