import { test } from "node:test"
import assert from "node:assert/strict"
import { blocksOf, branchesOf, readingOrder } from "../../app/javascript/easy_flow/canvas/reading.js"

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

test("puts a group step's box on a row of its own between the steps before and after it", () => {
  const nodes = [ { id: "outline", row: 0, column: 0 }, { id: "loop", row: 1, column: 0, holds: [ "write" ] },
                  { id: "write", row: 2, column: 0 }, { id: "approve", row: 3, column: 0 } ]
  const named = blocksOf(nodes).map((block) => ({ group: block.group?.id, steps: ids(block.steps) }))

  assert.deepEqual(named, [ { group: undefined, steps: [ "outline" ] }, { group: "loop", steps: [ "write" ] }, { group: undefined, steps: [ "approve" ] } ])
})

const chain = [ { id: "ask", row: 0, column: 0 }, { id: "gate", row: 1, column: 0 }, { id: "retry", row: 2, column: 0 } ]

test("names a branch that leads somewhere other than the next step", () => {
  const edges = [ { source: "gate", target: "ask" }, { source: "gate", target: "retry" } ]

  assert.deepEqual(branchesOf(chain[1], edges, chain).map((edge) => edge.target), [ "ask" ])
})

test("names a branch that carries an answer even when it leads to the next step", () => {
  const edges = [ { source: "gate", target: "retry", label: "false" } ]

  assert.deepEqual(branchesOf(chain[1], edges, chain).map((edge) => edge.label), [ "false" ])
})
