import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Records from "../../app/javascript/easy_flow/canvas/Records.jsx"

const drawn = () => renderToStaticMarkup(React.createElement(Records, {
  holds: { value: "string" }, labels: { value: "Value" }, rows: [ { value: "high" } ],
  onChange: () => {}, onSettle: () => {}
}))

test("borders each record with keystone's border colors", () => {
  assert.match(drawn(), /^<div[^>]*><div class="rounded-md border border-gray-200 dark:border-zinc-700"/)
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}<`))?.[1] || "").split(" ")

test("writes each record's field names in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "Value").includes("text-gray-500"))
})

test("offers removing a record as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Remove").includes("ks-button-secondary"))
})

test("offers adding a record as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Add").includes("ks-button-secondary"))
})

const drawnWith = (props) => renderToStaticMarkup(React.createElement(Records, {
  labels: {}, onChange: () => {}, onSettle: () => {}, ...props
}))

test("offers a select inside a record the options its field declares", () => {
  const html = drawnWith({ holds: { comparison: "select" }, rows: [ {} ], choices: { comparison: [ "more than", "less than" ] } })

  assert.match(html, /<option value="more than">more than<\/option><option value="less than">less than<\/option>/)
})

test("offers an output field inside a record the outputs of the step that record names", () => {
  const html = drawnWith({
    holds: { step: "previous_step", output: "from_step" }, rows: [ { step: "tests" } ], outputsOf: { output: "step" },
    choices: { output: { tests: [ { value: "coverage", label: "Coverage" } ], build: [ { value: "tokens", label: "Tokens" } ] } }
  })

  assert.match(html, /<option value="coverage">Coverage<\/option>/)
})
