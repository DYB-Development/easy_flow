import React, { useEffect, useState } from "react"
import Control from "./Control"
import Records from "./Records"
import Explanation from "./Explanation"
import Details from "./Details"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"

const panel = { width: 320, padding: "14px 16px", overflowY: "auto", display: "flex", flexDirection: "column", fontSize: 12 }

const foot = { marginTop: "auto", paddingTop: 12, display: "flex", flexDirection: "column", gap: 8 }

const Inspector = ({ node, fields, holds, labels, explanations, recordLabels, recordExplanations, recordChoices, recordOutputsOf, choices, onSave, onDelete, onClose, onPickPicture, refusal }) => {
  const [ draft, setDraft ] = useState(node.config)
  const [ pictureUrl, setPictureUrl ] = useState(node.picture_url)
  useEffect(() => setPictureUrl(node.picture_url), [ node.id, node.picture_url ])
  useEffect(() => setDraft(node.config), [ node.id, node.config ])

  const settle = (next) => {
    setDraft(next)
    if (JSON.stringify(next) !== JSON.stringify(node.config)) onSave(next)
  }

  return (
    <Panel as="aside" style={panel} className="max-sm:absolute max-sm:inset-0 max-sm:z-30 max-sm:!w-auto" data-inspector>
      <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8, marginBottom: 12 }}>
        <div>
          <p className="font-mono text-gray-500 dark:text-gray-400" style={{ fontSize: 11 }}>{node.id} · {node.type}</p>
          <h2 style={{ fontSize: 15, fontWeight: 600 }}>{node.label}</h2>
        </div>
        <button title="Close" onClick={onClose} className="text-gray-500 dark:text-gray-400"
                style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1 }}>×</button>
      </div>
      {refusal && <p className="text-red-800 dark:text-red-400" style={{ fontWeight: 600, marginBottom: 12 }} data-refusal>{refusal}</p>}
      {Object.entries(fields).map(([ name, type ]) => (
        <Label key={name}>
          <span style={{ display: "block", marginBottom: 3 }}>{labels[name] || name}</span>
          {type === "list"
            ? <Records holds={holds[name] || {}} labels={recordLabels[name] || {}} explanations={(recordExplanations || {})[name]} rows={draft[name]}
                       choices={{ ...(recordChoices || {})[name], ...(node.record_choices || {})[name] }}
                       outputsOf={(recordOutputsOf || {})[name]}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })} />
            : <Control name={name} type={type} value={draft[name]} choices={choices[name]} pictureUrl={pictureUrl}
                       onChange={(next) => setDraft({ ...draft, [name]: next })}
                       onSettle={(next) => settle({ ...draft, [name]: next })}
                       onPick={async (file) => {
                         const kept = await onPickPicture(file)
                         if (!kept) return
                         setPictureUrl(kept.url)
                         settle({ ...draft, [name]: kept.reference })
                       }} />}
          {(explanations || {})[name] && <Explanation text={explanations[name]} />}
        </Label>
      ))}
      <Details details={node.details || []} />
      <div style={foot}>
        {(node.links || []).length > 0 && (
          <div style={{ display: "flex", gap: 8 }}>
            {node.links.map((link) => (
              <Button key={link.address} variant="secondary" size="sm" className="flex-1" href={link.address}>{link.label}</Button>
            ))}
          </div>
        )}
        <Button variant="danger" size="sm" className="w-full" onClick={onDelete}>Delete step</Button>
      </div>
    </Panel>
  )
}

export default Inspector
