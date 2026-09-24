import { test } from "node:test"
import assert from "node:assert/strict"
import { worded } from "../../app/javascript/easy_flow/canvas/changes.js"

test("words a problem against the step it belongs to", () => {
  assert.equal(worded({ node: "branch", problem: "unreachable" }), "“branch” unreachable")
})

test("reads an underscored problem as words", () => {
  assert.equal(worded({ node: "gate", problem: "unmet_requirement" }), "“gate” unmet requirement")
})

test("words a problem belonging to no step", () => {
  assert.equal(worded({ node: null, problem: "missing_entry" }), "missing entry")
})
