import { test } from "node:test"
import assert from "node:assert/strict"
import { headerOf } from "../../app/javascript/easy_flow/canvas/group.js"

const forEach = { type: "for_each", type_name: "For each", config: { list: "outline.variants", concurrency: 3, on_item_failure: "continue" } }
const entry = { fields: { list: "string", concurrency: "integer", on_item_failure: "select" }, labels: { list: "List", concurrency: "Concurrency", on_item_failure: "On item failure" } }

test("makes the header from the step type's code and each setting's name and value", () => {
  assert.equal(headerOf(forEach, entry), "for_each · list: outline.variants · concurrency: 3 · on_item_failure: continue")
})

test("leaves a setting left blank out of the header", () => {
  assert.equal(headerOf({ ...forEach, config: { list: "outline.variants", concurrency: "" } }, entry), "for_each · list: outline.variants")
})

test("names the type and settings by their labels when the host hides step type codes", () => {
  assert.equal(headerOf({ ...forEach, config: { list: "outline.variants" } }, entry, true), "For each · List: outline.variants")
})
