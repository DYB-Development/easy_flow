import { test } from "node:test"
import assert from "node:assert/strict"
import { readingOrder } from "../../app/javascript/easy_flow/canvas/reading.js"

const ids = (nodes) => nodes.map((node) => node.id)

test("reads the steps in the order of the rows they sit in", () => {
  const nodes = [ { id: "last", row: 2, column: 0 }, { id: "first", row: 0, column: 0 }, { id: "middle", row: 1, column: 0 } ]

  assert.deepEqual(ids(readingOrder(nodes)), [ "first", "middle", "last" ])
})
