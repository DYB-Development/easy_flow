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

test("counts only the connections that lead into End", () => {
  const { from } = fromToolbar({ nodes: [ { id: "start", label: "Start", ends_here: false }, last, end ], edges: [ { source: "start", target: "last" }, { source: "last", target: "end" } ] })

  assert.equal(from, "last")
})

test("counts connections into every End in the flow", () => {
  const other = { id: "other_end", label: "Other end", ends_here: true }
  const { from } = fromToolbar({ nodes: [ last, end, other ], edges: [ { source: "last", target: "end" }, { source: "last", target: "other_end" } ] })

  assert.equal(from, undefined)
})

test("places no step on a connection in a flow with none into End", () => {
  assert.equal(fromToolbar({ nodes: [ last ], edges: [] }).from, undefined)
})

const oneIntoEnd = { nodes: [ last, end ], edges: [ { source: "last", target: "end" } ] }

test("says a step on the one connection into End goes between its two steps", () => {
  assert.equal(fromToolbar(oneIntoEnd).where, "Goes between Last question and End")
})

test("says a step with no connection to go on stays out of the flow", () => {
  assert.equal(fromToolbar({ nodes: [ last ], edges: [] }).where, "Goes beside the flow, not connected")
})
