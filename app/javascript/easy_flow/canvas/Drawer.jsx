import React, { useState } from "react"
import Tabs from "keystone_ui-react/src/Tabs.jsx"

const Rows = ({ checks }) => (
  <div>
    {checks.map((check, at) => <div key={at} data-check-row>{check.sentence}</div>)}
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
