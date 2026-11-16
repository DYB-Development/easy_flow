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

test("writes a section's heading in keystone's muted text color", () => {
  assert.match(drawn([ inputs ]), /class="[^"]*text-gray-500[^"]*"[^>]*>Inputs</)
})

const schemas = { heading: "Schemas", code: [ { summary: "input_schema", code: "{brief: Brief}" } ] }

test("shows each code block inside keystone's disclosure, opened from its summary line", () => {
  assert.match(drawn([ schemas ]), /<details class="ks-disclosure[^"]*"><summary[^>]*><span>input_schema<\/span>[\s\S]*<pre class="ks-code-block[^"]*"><code[^>]*>\{brief: Brief\}<\/code><\/pre>[\s\S]*<\/details>/)
})

const sectionClasses = (html) => (html.match(/<section class="([^"]*)"/)?.[1] || "").replaceAll("&amp;", "&").split(" ")

test("sets a section's values in a monospace font", () => {
  assert.ok(sectionClasses(drawn([ { ...inputs, columns: true } ])).includes("[&_dd]:font-mono"))
})

test("lines a row section's labels up in one column 90 pixels wide", () => {
  assert.ok(sectionClasses(drawn([ inputs ])).includes("[&_.ks-value-list-label]:basis-[90px]"))
})

test("draws a code section's summary lines plain, with no border around them", () => {
  assert.ok(sectionClasses(drawn([ schemas ])).includes("[&_.ks-disclosure]:border-0"))
})

test("stacks a section's heading over its contents, leaving room under the section", () => {
  assert.deepEqual([ "flex", "flex-col", "gap-1", "mb-3" ].filter((name) => sectionClasses(drawn([ inputs ])).includes(name)), [ "flex", "flex-col", "gap-1", "mb-3" ])
})

test("leaves a row section's heading in the panel's own font", () => {
  assert.ok(!sectionClasses(drawn([ inputs ])).includes("font-mono"))
})
