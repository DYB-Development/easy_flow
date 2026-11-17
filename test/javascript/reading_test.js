import { test } from "node:test"
import assert from "node:assert/strict"
import { blocksOf, branchLinesOf, joining, readingOrder } from "../../app/javascript/easy_flow/canvas/reading.js"

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

const labelled = chain.map((step) => ({ ...step, label: step.id }))

test("names a branch that leads somewhere other than the next step", () => {
  const edges = [ { source: "gate", target: "ask" }, { source: "gate", target: "retry" } ]

  assert.deepEqual(branchLinesOf(chain, edges, labelled).gate, [ "→ ask" ])
})

test("names a branch that carries an answer even when it leads to the next step", () => {
  const edges = [ { source: "gate", target: "retry", label: "false" } ]

  assert.deepEqual(branchLinesOf(chain, edges, labelled).gate, [ "false → retry" ])
})

test("writes a branch as its answer, an arrow and the name of the step it leads to", () => {
  const nodes = [ { ...chain[0], label: "Ask again" }, chain[1] ]

  assert.deepEqual(branchLinesOf(nodes, [ { source: "gate", target: "ask", label: "false" } ], nodes).gate, [ "false → Ask again" ])
})

test("writes a branch that leads to no step yet as leading nowhere yet", () => {
  const nodes = [ ...chain, { id: "gate--false", label: "false", placeholder: true } ]

  assert.deepEqual(branchLinesOf(chain, [ { source: "gate", target: "gate--false", label: "false" } ], nodes).gate, [ "false → nowhere yet" ])
})

test("finds the connection that joins a step to the step after it in a row", () => {
  const edges = [ { id: "ask-gate", source: "ask", target: "gate" }, { id: "gate-ask", source: "gate", target: "ask" } ]

  assert.equal(joining(edges, chain[0], chain[1])?.id, "ask-gate")
})

test("writes the branch lines of every step at once, keyed by the step they leave", () => {
  const nodes = [ ...labelled, { id: "gate--false", label: "false", placeholder: true, row: 1, column: 1 } ]
  const edges = [ { source: "ask", target: "gate" }, { source: "gate", target: "ask", label: "true" }, { source: "gate", target: "gate--false", label: "false" } ]

  assert.deepEqual(branchLinesOf(chain, edges, nodes), { ask: [], gate: [ "true → ask", "false → nowhere yet" ], retry: [] })
})

const counted = (count) => {
  const reads = { count: 0 }
  const watched = (value) => new Proxy(value, { get: (target, key) => { reads.count += 1; return target[key] } })
  const steps = Array.from({ length: count }, (_, at) => watched({ id: `s${at}`, label: `s${at}`, row: at, column: 0 }))
  const edges = steps.slice(1).map((step, at) => watched({ source: `s${at}`, target: step.id }))

  return { reads, steps, edges }
}

const readsPerStep = (work, count) => {
  const { reads, steps, edges } = counted(count)
  work(steps, edges)
  return reads.count / count
}

test("reads each step about as often in a flow of 400 steps as in a flow of 100 when writing branch lines", () => {
  const lines = (steps, edges) => branchLinesOf(steps, edges, steps)

  assert.ok(readsPerStep(lines, 400) < 2 * readsPerStep(lines, 100))
})

test("reads each step about as often in a flow of 400 steps as in a flow of 100 when splitting it into rows and boxes", () => {
  const blocks = (steps) => blocksOf(steps)

  assert.ok(readsPerStep(blocks, 400) < 2 * readsPerStep(blocks, 100))
})

test("reads each connection about as often in a flow of 400 steps as in a flow of 100 when finding the connection between each pair of steps in a row", () => {
  const joins = (steps, edges) => steps.slice(1).forEach((step, at) => joining(edges, steps[at], step))

  assert.ok(readsPerStep(joins, 400) < 2 * readsPerStep(joins, 100))
})
