import React, { useState } from "react"
import Panel from "keystone_ui-react/src/Panel.jsx"
import Input from "keystone_ui-react/src/Input.jsx"
import Button from "keystone_ui-react/src/Button.jsx"

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

const heading = { fontSize: 11, textTransform: "uppercase", letterSpacing: ".04em", padding: "8px 4px 2px" }

const item = { justifyContent: "flex-start", textAlign: "left", padding: "7px 9px", fontSize: 12, fontWeight: 400, cursor: "grab" }

const StepList = ({ entries, groups, onPick, onCarry, onDrop }) => {
  const [ query, setQuery ] = useState("")

  return (
    <Panel as="aside" aria-label="Steps" data-step-list className="hidden flex-col sm:flex" style={sidebar}>
      <Input type="search" aria-label="Search steps" placeholder="Search steps" value={query}
             onChange={(event) => setQuery(event.target.value)} style={{ marginBottom: 6, fontSize: 12 }} />
      {listed(entries, groups, query).map((section) => (
        <React.Fragment key={section.heading || ""}>
          {section.heading && <div className="text-gray-500 dark:text-gray-400" style={heading}>{section.heading}</div>}
          {section.entries.map((entry) => (
            <Button key={entry.type} variant="secondary" size="sm" data-step-type={entry.type} style={item} draggable
                    onClick={() => onPick(entry)}
                    onDragStart={(event) => { event.dataTransfer.effectAllowed = "copy"; event.dataTransfer.setData("text/plain", entry.type); onCarry(entry) }}
                    onDragEnd={onDrop}>{entry.label}</Button>
          ))}
        </React.Fragment>
      ))}
    </Panel>
  )
}

export default StepList
