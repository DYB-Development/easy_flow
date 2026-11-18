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
