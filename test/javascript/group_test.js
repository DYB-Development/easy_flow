import { test } from "node:test"
import assert from "node:assert/strict"
import { boxAround, boxAt, headerOf, linksOutside } from "../../app/javascript/easy_flow/canvas/group.js"

const forEach = { type: "for_each", type_name: "For each", config: { list: "outline.variants", concurrency: 3, on_item_failure: "continue" } }
const entry = { fields: { list: "string", concurrency: "integer", on_item_failure: "select" }, labels: { list: "List", concurrency: "Concurrency", on_item_failure: "On item failure" } }

test("makes the header from the step type's code and each setting's name and value", () => {
  assert.equal(headerOf(forEach, entry), "for_each · list: outline.variants · concurrency 3 · on_item_failure: continue")
})

test("leaves a setting left blank out of the header", () => {
  assert.equal(headerOf({ ...forEach, config: { list: "outline.variants", concurrency: "" } }, entry), "for_each · list: outline.variants")
})

test("names the type and settings by their labels when the host hides step type codes", () => {
  assert.equal(headerOf({ ...forEach, config: { list: "outline.variants" } }, entry, true), "For each · List: outline.variants")
})

test("leaves a setting holding a list of entries out of the header", () => {
  const listing = { ...entry, fields: { ...entry.fields, items: "list" } }

  assert.equal(headerOf({ ...forEach, config: { list: "outline.variants", items: [ { value: "a" } ] } }, listing), "for_each · list: outline.variants")
})

test("draws the box around its header and steps with room inside its border", () => {
  const boxes = [ { left: 110, top: 60, width: 240, height: 20 }, { left: 110, top: 140, width: 240, height: 60 } ]

  assert.deepEqual(boxAround(boxes, { left: 10, top: 10 }, { scrollLeft: 0, scrollTop: 0 }), { left: 88, top: 40, width: 264, height: 160 })
})

test("finds the group step whose box a point falls in", () => {
  const boxes = [ { id: "loop", bounds: { left: 88, top: 40, width: 264, height: 160 } } ]

  assert.equal(boxAt(boxes, { x: 100, y: 190 }), "loop")
})

test("draws no connection from a group step to a step it holds", () => {
  const nodes = [ { id: "loop", holds: [ "write" ] }, { id: "write" }, { id: "after" } ]
  const links = [ { source: "loop", target: "write" }, { source: "write", target: "after" } ]

  assert.deepEqual(linksOutside(links, nodes), [ { source: "write", target: "after" } ])
})
