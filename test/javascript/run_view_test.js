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

test("draws a group's header line at the top of the group's box", () => {
  assert.match(drawn(), /data-group-box="variants"[^>]*><div[^>]*><div data-group-header="variants"[^>]*>for_each · list: outline\.variants · concurrency 3<\/div>/)
})

test("draws no buttons for changing the flow", () => {
  assert.doesNotMatch(drawn(), /<button/)
})

test("starts its rows at its own top left corner, with none of the room the editing canvas keeps for its toolbar", () => {
  assert.match(drawn(), /data-flow-rows="true" style="[^"]*padding:0/)
})
