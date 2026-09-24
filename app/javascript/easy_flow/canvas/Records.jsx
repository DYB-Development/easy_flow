import React from "react"
import Control from "./Control"
import { amended } from "./rows"
import Button from "keystone_ui-react/src/Button.jsx"

const Records = ({ holds, labels, rows, onChange, onSettle }) => {
  const kept = Array.isArray(rows) ? rows : []
  const amend = (index, name, next, settle) => {
    const updated = amended(kept, index, name, next)
    settle ? onSettle(updated) : onChange(updated)
  }

  return (
    <div style={{ marginBottom: 12 }}>
      {kept.map((row, index) => (
        <div key={index} className="rounded-md border border-gray-200 dark:border-zinc-700" style={{ padding: "8px 8px 2px", marginBottom: 6 }}>
          {Object.entries(holds).map(([ name, type ]) => (
            <label key={name} style={{ display: "block" }}>
              <span className="text-gray-500 dark:text-gray-400" style={{ display: "block", marginBottom: 2, fontSize: 11 }}>{(labels || {})[name] || name}</span>
              <Control type={type} value={row[name]}
                       onChange={(next) => amend(index, name, next, false)}
                       onSettle={(next) => amend(index, name, next, true)} />
            </label>
          ))}
          <Button variant="secondary" size="sm" className="mb-1.5"
                  onClick={() => onSettle(kept.filter((_, at) => at !== index))}>Remove</Button>
        </div>
      ))}
      <Button variant="secondary" size="sm" className="w-full" onClick={() => onSettle([ ...kept, {} ])}>Add</Button>
    </div>
  )
}

export default Records
