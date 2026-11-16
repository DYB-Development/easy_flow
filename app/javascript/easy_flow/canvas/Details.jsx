import React from "react"
import ValueList from "keystone_ui-react/src/ValueList.jsx"

const Details = ({ details }) => (
  <>
    {details.map((section, at) => (
      <section key={at}>
        {section.heading && <div className="text-gray-500 dark:text-gray-400">{section.heading}</div>}
        <ValueList rows={section.values} columns={section.columns} />
      </section>
    ))}
  </>
)

export default Details
