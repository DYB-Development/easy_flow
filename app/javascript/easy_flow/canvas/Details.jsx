import React from "react"
import ValueList from "keystone_ui-react/src/ValueList.jsx"
import Disclosure from "keystone_ui-react/src/Disclosure.jsx"
import Code from "keystone_ui-react/src/Code.jsx"

const VALUES = "[&_dd]:font-mono"

const ROWS = "font-mono [&_.ks-value-list]:flex [&_.ks-value-list]:flex-col [&_.ks-value-list]:gap-1 [&_.ks-value-list-row]:gap-2 [&_.ks-value-list-row]:py-0 [&_.ks-value-list-row]:border-0 [&_.ks-value-list-label]:basis-[90px]"

const CODE = "border-t border-gray-200 pt-2.5 dark:border-zinc-700 [&_.ks-disclosure]:border-0 [&_.ks-disclosure-summary]:flex-row-reverse [&_.ks-disclosure-summary]:justify-end [&_.ks-disclosure-summary]:gap-1 [&_.ks-disclosure-summary]:p-0 [&_.ks-disclosure-summary]:font-normal [&_.ks-disclosure-body]:p-0 [&_.ks-disclosure-body]:pt-1.5 [&_.ks-code-block]:p-2 [&_.ks-code-block]:text-[11px]"

const looks = (section) => {
  if (!section.values) return CODE
  return section.columns ? VALUES : `${VALUES} ${ROWS}`
}

const Details = ({ details }) => (
  <>
    {details.map((section, at) => (
      <section key={at} className={looks(section)}>
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
