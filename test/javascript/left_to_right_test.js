import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import LeftToRight from "../../app/javascript/easy_flow/canvas/LeftToRight.jsx"

const step = (id, row) => ({ id, label: id, row, column: 0 })
const chain = [ step("ask", 0), step("gate", 1) ]

const drawn = (nodes, edges = [], given = {}) => renderToStaticMarkup(React.createElement(LeftToRight, {
  nodes, edges, draw: (node) => React.createElement("div", { "data-step": node.id }), ...given
}))

test("joins a step to the next step it leads to with a short line", () => {
  assert.match(drawn(chain, [ { id: "ask-gate-0", source: "ask", target: "gate" } ]), /data-joint="ask-gate-0"/)
})

test("lays a group step's steps out in a row inside its box below its header", () => {
  const nodes = [ { ...step("loop", 0), holds: [ "write", "check" ] }, step("write", 1), step("check", 2) ]

  assert.match(drawn(nodes), /data-group-box="loop"[^>]*><div data-step="loop"><\/div><div data-flow-row[^>]*>.*data-step="write".*data-step="check"/)
})
