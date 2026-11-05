import { test } from "node:test"
import assert from "node:assert/strict"
import { warned } from "../../app/javascript/easy_flow/canvas/changes.js"

test("says what to do about one unconnected step", () => {
  assert.equal(warned([ { id: "a", name: "Ask" } ]), "“Ask” is not connected to the flow and will be removed. Remove it to go on, or cancel and connect it first.")
})

test("says what to do about several unconnected steps", () => {
  assert.equal(warned([ { id: "a", name: "Ask" }, { id: "b", name: "Tell" } ]), "“Ask”, “Tell” are not connected to the flow and will be removed. Remove them to go on, or cancel and connect them first.")
})

test("names each unconnected step in the warning", () => {
  assert.equal(warned([ { id: "a", label: "a", name: "Ask" }, { id: "b", label: "b", name: "Tell" } ]).split(" are")[0], "“Ask”, “Tell”")
})
