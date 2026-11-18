import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import StepRows from "../../app/javascript/easy_flow/canvas/StepRows.jsx"

const step = (id, given = {}) => ({ id, label: id, ...given })

const drawn = (nodes, edges, given = {}) => renderToStaticMarkup(React.createElement(StepRows, {
  nodes, edges, draw: (node) => React.createElement("div", { "data-step": node.id }), joints: {}, ...given
}))

test("lists under a step each of its connections, by the answer it is taken on and the step it leads to", () => {
  const nodes = [ step("gate"), step("yes", { label: "Write variant" }), step("no", { label: "Rejected" }) ]
  const edges = [ { id: "gate-yes-0", source: "gate", target: "yes", label: "true" }, { id: "gate-no-1", source: "gate", target: "no", label: "false" } ]

  assert.match(drawn(nodes, edges), /data-step="gate".*true → Write variant.*false → Rejected.*data-step="yes"/)
})
