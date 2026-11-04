import { test } from "node:test"
import assert from "node:assert/strict"
import { fromToolbar } from "../../app/javascript/easy_flow/canvas/placing.js"

const end = { id: "end", label: "End", ends_here: true }
const last = { id: "last", label: "Last question", ends_here: false }

test("places a step on the one connection into End", () => {
  const { from, to } = fromToolbar({ nodes: [ last, end ], edges: [ { source: "last", target: "end" } ] })

  assert.deepEqual([ from, to ], [ "last", "end" ])
})

test("places no step on a connection when several lead into End", () => {
  const other = { id: "other", label: "Other", ends_here: false }
  const { from } = fromToolbar({ nodes: [ last, other, end ], edges: [ { source: "last", target: "end" }, { source: "other", target: "end" } ] })

  assert.equal(from, undefined)
})
