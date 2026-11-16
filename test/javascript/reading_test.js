import { test } from "node:test"
import assert from "node:assert/strict"
import { readingOrder } from "../../app/javascript/easy_flow/canvas/reading.js"

const ids = (nodes) => nodes.map((node) => node.id)

test("reads the steps in the order of the rows they sit in", () => {
  const nodes = [ { id: "last", row: 2, column: 0 }, { id: "first", row: 0, column: 0 }, { id: "middle", row: 1, column: 0 } ]

  assert.deepEqual(ids(readingOrder(nodes)), [ "first", "middle", "last" ])
})

test("reads steps that share a row from left to right", () => {
  const nodes = [ { id: "no", row: 1, column: 2 }, { id: "yes", row: 1, column: 0 } ]

  assert.deepEqual(ids(readingOrder(nodes)), [ "yes", "no" ])
})

test("reads the steps a group step holds right after the group step", () => {
  const nodes = [ { id: "loop", row: 0, column: 0, holds: [ "write", "check" ] }, { id: "write", row: 1, column: 0 },
                  { id: "aside", row: 1, column: 2 }, { id: "check", row: 2, column: 0 } ]

  assert.deepEqual(ids(readingOrder(nodes)), [ "loop", "write", "check", "aside" ])
})
