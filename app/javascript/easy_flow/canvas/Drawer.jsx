import React, { useState } from "react"
import Tabs from "keystone_ui-react/src/Tabs.jsx"

const Drawer = ({ checks, tabs, onSelect, opened = "validation" }) => {
  const [ open, setOpen ] = useState(opened)

  return (
    <section aria-label="Validation and tests" data-drawer>
      <Tabs align="start" shape="underline" value={open} onChange={setOpen}
            tabs={[ { value: "validation", label: "Validation" } ]} />
    </section>
  )
}

export default Drawer
