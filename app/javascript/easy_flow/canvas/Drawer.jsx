import React, { useState } from "react"
import Tabs from "keystone_ui-react/src/Tabs.jsx"

const LEVELS = { error: "text-red-800 dark:text-red-400", ok: "text-emerald-800 dark:text-emerald-400" }

const row = { display: "flex", gap: 8, textAlign: "left" }

const Row = ({ check, onSelect }) => {
  const shown = <>
    <span className={LEVELS[check.level]} style={{ fontWeight: 500 }}>{check.level}</span>
    {check.node && <span className="font-mono">{check.node}</span>}
    <span>{check.sentence}</span>
  </>

  return check.node
    ? <button type="button" data-check-row data-step-id={check.node} style={{ ...row, border: "none", background: "none", padding: 0, cursor: "pointer", font: "inherit", color: "inherit" }} onClick={() => onSelect(check.node)}>{shown}</button>
    : <div data-check-row style={row}>{shown}</div>
}

const Rows = ({ checks, onSelect }) => (
  <div>
    {checks.map((check, at) => <Row key={at} check={check} onSelect={onSelect} />)}
  </div>
)

const Drawer = ({ checks, tabs, onSelect, opened = "validation" }) => {
  const [ open, setOpen ] = useState(opened)

  return (
    <section aria-label="Validation and tests" data-drawer>
      <Tabs align="start" shape="underline" value={open} onChange={setOpen}
            tabs={[ { value: "validation", label: "Validation", count: checks.filter((check) => check.level === "error").length, content: <Rows checks={checks} onSelect={onSelect} /> },
                    ...tabs.map((tab) => ({ value: tab.label, label: tab.label, count: tab.count ?? "", content: <div data-drawer-content dangerouslySetInnerHTML={{ __html: tab.content }} /> })) ]} />
    </section>
  )
}

export default Drawer
