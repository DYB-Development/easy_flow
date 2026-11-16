import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import RunView from "../../app/javascript/easy_flow/canvas/RunView.jsx"

const step = (id, row, given = {}) => ({ id, type: "agent", label: id, row, column: 0, state: "done", status: "1s", ...given })

const group = step("variants", 1, { type: "for_each", holds: [ "write" ], config: { list: "outline.variants", concurrency: 3, holds: [ "write" ] },
                                    fields: { list: "string", concurrency: "integer" } })

const nodes = [ step("outline", 0), group, step("write", 2), step("approve", 3, { state: "paused" }), step("publish", 4, { state: "pending" }) ]

const edges = [ { id: "outline-variants-0", source: "outline", target: "variants" }, { id: "variants-write-1", source: "variants", target: "write" },
                { id: "write-approve-2", source: "write", target: "approve" }, { id: "approve-publish-3", source: "approve", target: "publish" } ]

const drawn = (given = {}) => renderToStaticMarkup(React.createElement(RunView, { nodes, edges, selected: null, ...given }))

test("draws a held step inside its group's box under the group's header line", () => {
  assert.match(drawn(), /data-group-box="variants"[^>]*><div data-group-header="variants"[^>]*>for_each · list: outline\.variants · concurrency 3<\/div><div data-flow-row[^>]*>.*data-step="write"/)
})

test("draws no buttons for changing the flow", () => {
  assert.doesNotMatch(drawn(), /<button/)
})
