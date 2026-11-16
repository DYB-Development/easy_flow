import React, { useState } from "react"
import Tabs from "keystone_ui-react/src/Tabs.jsx"

const LEVELS = { error: "text-red-800 dark:text-red-400", ok: "text-emerald-800 dark:text-emerald-400" }

const row = { display: "flex", gap: 8, textAlign: "left" }

const Rows = ({ checks }) => (
  <div>
    {checks.map((check, at) => (
      <div key={at} data-check-row style={row}>
        <span className={LEVELS[check.level]} style={{ fontWeight: 500 }}>{check.level}</span>
        {check.node && <span className="font-mono">{check.node}</span>}
        <span>{check.sentence}</span>
      </div>
    ))}
  </div>
)

const Drawer = ({ checks, tabs, onSelect, opened = "validation" }) => {
  const [ open, setOpen ] = useState(opened)

  return (
    <section aria-label="Validation and tests" data-drawer>
      <Tabs align="start" shape="underline" value={open} onChange={setOpen}
            tabs={[ { value: "validation", label: "Validation", count: checks.filter((check) => check.level === "error").length, content: <Rows checks={checks} /> },
                    ...tabs.map((tab) => ({ value: tab.label, label: tab.label, count: tab.count ?? "" })) ]} />
    </section>
  )
}

export default Drawer
