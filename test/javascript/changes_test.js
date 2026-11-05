import { test } from "node:test"
import assert from "node:assert/strict"
import { warned, worded } from "../../app/javascript/easy_flow/canvas/changes.js"

test("words a problem against the step it belongs to", () => {
  assert.equal(worded({ node: "branch", problem: "unreachable" }), "“branch” unreachable")
})

test("reads an underscored problem as words", () => {
  assert.equal(worded({ node: "gate", problem: "unmet_requirement" }), "“gate” unmet requirement")
})

test("words a problem belonging to no step", () => {
  assert.equal(worded({ node: null, problem: "missing_entry" }), "missing entry")
})

test("names each unconnected step in the warning", () => {
  assert.equal(warned([ { id: "a", label: "Ask" }, { id: "b", label: "Tell" } ]), "“Ask”, “Tell” are not connected to the flow and will be removed.")
})
