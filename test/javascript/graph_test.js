import { test } from "node:test"
import assert from "node:assert/strict"
import { layOut } from "../../app/javascript/easy_flow/canvas/graph.js"

const step = (id, given = {}) => ({ id, label: id, ...given })
const link = (source, target, label) => ({ id: `${source}-${target}`, source, target, label })

const columnOf = (graph, id) => graph.places[id].column

test("puts a step one column to the right of the step that leads into it", () => {
  const graph = layOut([ step("ask"), step("gate") ], [ link("ask", "gate") ])

  assert.equal(columnOf(graph, "gate"), columnOf(graph, "ask") + 1)
})

test("puts a step a connection loops back to to the left of the step it loops back from", () => {
  const graph = layOut([ step("start"), step("write"), step("check"), step("retry") ],
                       [ link("start", "write"), link("write", "check"), link("check", "retry"), link("retry", "write") ])

  assert.deepEqual([ "start", "write", "check", "retry" ].map((id) => columnOf(graph, id)), [ 0, 1, 2, 3 ])
})

const rowOf = (graph, id) => graph.places[id].row

test("fans the branches of a step out into separate rows", () => {
  const graph = layOut([ step("gate"), step("yes"), step("no") ], [ link("gate", "yes", "true"), link("gate", "no", "false") ])

  assert.notEqual(rowOf(graph, "yes"), rowOf(graph, "no"))
})
