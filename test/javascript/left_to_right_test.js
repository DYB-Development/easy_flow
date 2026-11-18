import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import LeftToRight from "../../app/javascript/easy_flow/canvas/LeftToRight.jsx"

const step = (id, given = {}) => ({ id, label: id, row: 0, column: 0, ...given })
const chain = [ step("ask"), step("gate") ]
const editing = { onInsert: () => {}, onRemove: () => {}, onDrop: () => {} }

const drawn = (nodes, edges = [], given = {}) => renderToStaticMarkup(React.createElement(LeftToRight, {
  nodes, edges, draw: (node) => React.createElement("div", { "data-step": node.id }), joints: {}, ...given
}))

test("joins a step to the next step it leads to with a short line", () => {
  assert.match(drawn(chain, [ { id: "ask-gate-0", source: "ask", target: "gate" } ], { joints: editing }), /data-joint="ask-gate-0"/)
})

test("draws a line for every connection, including each branch and the connection into an End step", () => {
  const nodes = [ step("gate"), step("yes"), step("end", { ends_here: true }) ]
  const edges = [ { id: "gate-yes-0", source: "gate", target: "yes", label: "true" }, { id: "gate-end-1", source: "gate", target: "end", label: "false" },
                  { id: "yes-end-2", source: "yes", target: "end" } ]

  assert.deepEqual([ ...drawn(nodes, edges).matchAll(/<path data-link="([^"]+)"/g) ].map((found) => found[1]), [ "gate-yes-0", "gate-end-1", "yes-end-2" ])
})

test("puts a connection's insert and remove buttons on its line, beside the card the line leaves", () => {
  assert.match(drawn(chain, [ { id: "ask-gate-0", source: "ask", target: "gate" } ], { joints: editing }), /data-joint="ask-gate-0"[^>]*style="position:absolute;left:\d+px;top:\d+px/)
})

test("labels a branch's line with the answer it is taken on", () => {
  assert.match(drawn(chain, [ { id: "ask-gate-0", source: "ask", target: "gate", label: "failed" } ]), /data-link-label="ask-gate-0"[^>]*>failed</)
})

test("draws one step per row instead of the graph on a screen as narrow as a phone", () => {
  globalThis.window = { matchMedia: (query) => ({ media: query, matches: false, addEventListener: () => {}, removeEventListener: () => {} }) }
  try {
    assert.match(drawn(chain, [ { id: "ask-gate-0", source: "ask", target: "gate" } ]), /data-step-row="ask"/)
  } finally {
    delete globalThis.window
  }
})
