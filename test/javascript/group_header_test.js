import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import GroupHeader from "../../app/javascript/easy_flow/canvas/GroupHeader.jsx"

const header = (overrides = {}) => GroupHeader({ node: { id: "loop" }, header: "for_each · list: outline.variants", onSelect: () => {}, ...overrides })

test("writes a group step's header line", () => {
  assert.match(renderToStaticMarkup(React.createElement(GroupHeader, { node: { id: "loop" }, header: "for_each · list: outline.variants", onSelect: () => {} })), />for_each · list: outline.variants</)
})

test("opens the group step's settings when its header is selected", () => {
  let opened = false
  header({ onSelect: () => { opened = true } }).props.onClick()

  assert.ok(opened)
})
