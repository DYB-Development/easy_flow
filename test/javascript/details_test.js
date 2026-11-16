import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Details from "../../app/javascript/easy_flow/canvas/Details.jsx"

const drawn = (details) => renderToStaticMarkup(React.createElement(Details, { details }))

const inputs = { heading: "Inputs", columns: false, values: [ { label: "brief", value: "load_brief.out.brief" } ] }

test("shows a section's values as keystone's value list", () => {
  assert.match(drawn([ inputs ]), /class="ks-value-list[^"]*"[\s\S]*<dt[^>]*>brief<\/dt><dd[^>]*>load_brief\.out\.brief<\/dd>/)
})
