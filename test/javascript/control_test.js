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

test("offers a flow the step runs as a choice rather than free text", () => {
  assert.match(drawn({ type: "flow", value: "", choices: [ { value: "7", label: "Onboarding" } ] }), /^<select/)
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

test("draws each flow a step plays as a checkbox labelled with the flow's title", () => {
  assert.match(drawn({ type: "flows", value: [], choices: [ { value: "7", label: "Onboarding" } ] }), /<input(?=[^>]*type="checkbox")[^>]*>.*Onboarding/)
})

test("draws a picture setting as a file input that takes images", () => {
  assert.match(drawn({ type: "picture", value: "" }), /<input[^>]*type="file"[^>]*accept="image\/\*"/)
})

test("shows a step's current picture above its file input", () => {
  assert.match(drawn({ type: "picture", value: "picture-1", pictureUrl: "/pictures/picture-1" }), /<img[^>]*src="\/pictures\/picture-1"/)
})

test("removes a step's picture when the author asks", () => {
  let settled = null
  const tree = Control({ type: "picture", value: "picture-1", pictureUrl: "/pictures/picture-1", onSettle: (value) => { settled = value }, onPick: () => {} })
  const remove = [ tree.props.children ].flat(Infinity).filter(Boolean).find((element) => element.props?.["data-remove-picture"])

  remove.props.onClick()

  assert.equal(settled, "")
})

const aliases = [
  { value: "prod", label: "prod → v22", hint: "p 0.84 · n 1,920" },
  { value: "candidate", label: "candidate → v23", hint: "p 0.87 · n 240" }
]

test("draws each choice of a radio card setting as a keystone radio card", () => {
  assert.equal(drawn({ type: "radio_cards", value: "prod", choices: aliases }).match(/class="ks-radio-card /g)?.length, 2)
})

test("saves the value of the radio card the author chooses", () => {
  let settled = null
  const tree = Control({ type: "radio_cards", value: "prod", choices: aliases, onSettle: (value) => { settled = value } })

  const cards = [ tree, tree.props.children ].flat(Infinity).find((element) => element?.props?.onChange)

  cards.props.onChange("candidate")

  assert.equal(settled, "candidate")
})
