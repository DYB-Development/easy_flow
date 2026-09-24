import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Control from "../../app/javascript/easy_flow/canvas/Control.jsx"

const drawn = (given) => renderToStaticMarkup(React.createElement(Control, {
  type: "previous_step", value: "a", choices: [ { value: "a", label: "Budget?" } ],
  onChange: () => {}, onSettle: () => {}, ...given
}))

const firstTag = (html) => html.match(/^<[^>]*>/)[0]

test("offers a step that comes before as a choice rather than free text", () => {
  assert.match(drawn({}), /^<select/)
})

test("offers an answer drawn from another step as a choice rather than free text", () => {
  assert.match(drawn({ type: "from_step", choices: [ { value: "high", label: "Over $1k" } ] }), /^<select/)
})

test("draws free text as a keystone input", () => {
  assert.match(firstTag(drawn({ type: "string", value: "" })), /class="ks-input[ "]/)
})

test("draws a number as a keystone input", () => {
  assert.match(firstTag(drawn({ type: "integer", value: 1 })), /class="ks-input[ "]/)
})

test("draws a choice as a keystone input", () => {
  assert.match(firstTag(drawn({})), /class="ks-input[ "]/)
})

test("draws a yes or no setting as a keystone checkbox", () => {
  assert.match(firstTag(drawn({ type: "boolean", value: true })), /class="ks-checkbox"/)
})

test("draws each option of a pick-several setting as a keystone checkbox", () => {
  assert.match(drawn({ type: "multi_select", value: [], choices: [ "red" ] }), /<input(?=[^>]*type="checkbox")(?=[^>]*class="ks-checkbox")[^>]*>/)
})
