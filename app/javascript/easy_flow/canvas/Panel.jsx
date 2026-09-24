import React from "react"
import KeystonePanel from "keystone_ui-react/src/Panel.jsx"
import Button from "keystone_ui-react/src/Button.jsx"
import Input from "keystone_ui-react/src/Input.jsx"
import { Label } from "keystone_ui-react/src/FieldText.jsx"
import { worded } from "./changes"
import { standing } from "./flow"

const sheet = { width: 280, padding: 20, overflowY: "auto" }
const heading = { fontWeight: 600, marginBottom: 6, marginTop: 14 }
const item = { fontSize: 12, marginBottom: 4, lineHeight: 1.4 }
const caption = { display: "block", marginBottom: 3 }

const settling = (flow, name, onSaveDetails) => (event) => {
  if (event.target.value !== (flow[name] ?? "")) onSaveDetails({ [name]: event.target.value })
}

const Panel = ({ flow, changes, problems, refusal, notice, onCreate, onPublish, onSaveDetails, onClose }) => (
  <KeystonePanel as="aside" style={sheet} data-builder-panel>
    <div style={{ display: "flex", alignItems: "start", justifyContent: "space-between", gap: 8 }}>
      <h2 style={{ fontWeight: 600 }} data-flow-name>{flow.title || flow.slug}</h2>
      <button title="Close" onClick={onClose} className="text-gray-500 dark:text-gray-400"
              style={{ border: "none", background: "none", cursor: "pointer", fontSize: 18, lineHeight: 1 }}>×</button>
    </div>
    <a className="text-accent-600 dark:text-accent-400" style={{ fontSize: 12, display: "block" }} href={flow.history_url} data-history>{standing(flow)}</a>

    <h2 style={heading}>Problems</h2>
    {refusal && <p className="text-red-800 dark:text-red-400" style={{ ...item, fontWeight: 600 }} data-refusal>{refusal}</p>}
    {notice && !refusal && <p className="text-emerald-800 dark:text-emerald-400" style={{ ...item, fontWeight: 600 }} data-notice>{notice}</p>}
    {problems.length === 0 && !refusal
      ? <p className="text-gray-500 dark:text-gray-400" style={{ fontSize: 12 }}>Nothing wrong with this flow.</p>
      : problems.map((problem) => (
          <p key={`${problem.node}-${problem.problem}`} className="text-amber-700 dark:text-amber-400" style={item} data-problem>⚠ {worded(problem)}</p>
        ))}

    <h2 style={heading}>Changes since the last version</h2>
    {changes.length === 0
      ? <p className="text-gray-500 dark:text-gray-400" style={{ fontSize: 12 }}>Nothing has changed.</p>
      : changes.map((change, at) => <p key={at} style={item} data-change>{change}</p>)}

    <h2 style={heading}>Details</h2>
    <Label>
      <span style={caption}>Title</span>
      <Input className="mb-3" defaultValue={flow.title ?? ""} onBlur={settling(flow, "title", onSaveDetails)} data-flow-title />
    </Label>

    <Label>
      <span style={caption}>Start label</span>
      <Input className="mb-3" defaultValue={flow.start_label ?? ""} onBlur={settling(flow, "start_label", onSaveDetails)} data-flow-start-label />
    </Label>

    <div style={{ marginTop: 16 }}>
      <Button variant="secondary" size="sm" className="w-full mb-1.5" onClick={onCreate} data-create-version>Create version</Button>
      <Button size="sm" className="w-full mb-1.5" onClick={onPublish} data-publish>Publish</Button>
      <Button variant="secondary" size="sm" className="w-full mb-1.5" href={flow.definition_url} data-definition>Definition</Button>
      <Button variant="secondary" size="sm" className="w-full mb-1.5" href={flow.details_url} data-details>Edit details</Button>
    </div>
  </KeystonePanel>
)

export default Panel
