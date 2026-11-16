import React, { useState } from "react"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Input from "keystone_ui-react/src/Input.jsx"

const matching = (query) => (entry) => entry.label.toLowerCase().includes(query.trim().toLowerCase())

export const listed = (entries, groups, query = "") => {
  const grouped = Object.values(groups).flat()
  const sections = Object.entries(groups).map(([ heading, types ]) => ({
    heading,
    entries: types.map((type) => entries.find((entry) => entry.type === type)).filter(Boolean)
  }))

  return [ ...sections, { heading: null, entries: entries.filter((entry) => !grouped.includes(entry.type)) } ]
    .map((section) => ({ ...section, entries: section.entries.filter(matching(query)) }))
    .filter((section) => section.entries.length > 0)
}

const sidebar = { width: 200, flex: "none", boxSizing: "border-box", padding: "14px 12px", gap: 6, fontSize: 12, overflowY: "auto", borderWidth: "0 1px 0 0" }

const StepList = () => {
  const [ query, setQuery ] = useState("")

  return (
    <Panel as="aside" aria-label="Steps" data-step-list className="hidden flex-col sm:flex" style={sidebar}>
      <Input type="search" aria-label="Search steps" placeholder="Search steps" value={query}
             onChange={(event) => setQuery(event.target.value)} style={{ marginBottom: 6, fontSize: 12 }} />
    </Panel>
  )
}

export default StepList
