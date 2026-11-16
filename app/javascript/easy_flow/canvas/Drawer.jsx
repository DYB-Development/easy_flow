import React, { useState } from "react"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Tabs from "keystone_ui-react/src/Tabs.jsx"

const LEVELS = { error: "text-red-800 dark:text-red-400", ok: "text-emerald-800 dark:text-emerald-400" }

const LOOK = "mx-6 mb-6 flex max-h-[45%] flex-none flex-col overflow-y-auto rounded-lg max-sm:m-0 max-sm:max-h-none max-sm:rounded-none [&_.ks-tab-bar]:mb-0 [&_.ks-tab-bar]:px-2"

const COVERING = "max-sm:absolute max-sm:inset-0 max-sm:z-20"

const body = { padding: "10px 14px", fontSize: 12, display: "flex", flexDirection: "column", gap: 6 }

const row = { display: "flex", gap: 8, textAlign: "left" }

const whole = { flexShrink: 0, whiteSpace: "nowrap" }

const Row = ({ check, onSelect }) => {
  const shown = <>
    <span className={LEVELS[check.level]} style={{ ...whole, fontWeight: 500 }}>{check.level}</span>
    {check.node && <span className="font-mono" style={whole}>{check.node}</span>}
    <span>{check.sentence}</span>
  </>

  return check.node
    ? <button type="button" data-check-row data-step-id={check.node} style={{ ...row, border: "none", background: "none", padding: 0, cursor: "pointer", font: "inherit", color: "inherit" }} onClick={() => onSelect(check.node)}>{shown}</button>
    : <div data-check-row style={row}>{shown}</div>
}

const Rows = ({ checks, onSelect }) => (
  <div style={body}>
    {checks.map((check, at) => <Row key={at} check={check} onSelect={onSelect} />)}
  </div>
)

const onAPhone = () => typeof window !== "undefined" && Boolean(window.matchMedia?.("(max-width: 639px)").matches)

const Drawer = ({ checks, tabs, onSelect, opened = onAPhone() ? null : "validation" }) => {
  const [ open, setOpen ] = useState(opened)

  return (
    <Panel as="section" aria-label="Validation and tests" data-drawer className={open ? `${LOOK} ${COVERING}` : LOOK}>
      <Tabs align="start" shape="underline" value={open} onChange={(chosen) => setOpen(chosen === open ? null : chosen)}
            tabs={[ { value: "validation", label: "Validation", count: checks.filter((check) => check.level === "error").length, content: <Rows checks={checks} onSelect={onSelect} /> },
                    ...tabs.map((tab) => ({ value: tab.label, label: tab.label, count: tab.count ?? "", content: <div data-drawer-content style={body} dangerouslySetInnerHTML={{ __html: tab.content }} /> })) ]} />
    </Panel>
  )
}

export default Drawer
