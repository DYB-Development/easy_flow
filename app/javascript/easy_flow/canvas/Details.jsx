import React from "react"
import ValueList from "keystone_ui-react/src/ValueList.jsx"
import Disclosure from "keystone_ui-react/src/Disclosure.jsx"
import Code from "keystone_ui-react/src/Code.jsx"

const Details = ({ details }) => (
  <>
    {details.map((section, at) => (
      <section key={at}>
        {section.heading && <div className="text-gray-500 dark:text-gray-400">{section.heading}</div>}
        {section.values && <ValueList rows={section.values} columns={section.columns} />}
        {section.code && section.code.map((block) => (
          <Disclosure key={block.summary} summary={block.summary}>
            <Code>{block.code}</Code>
          </Disclosure>
        ))}
      </section>
    ))}
  </>
)

export default Details
