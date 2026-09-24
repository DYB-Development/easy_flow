import { test } from "node:test"
import assert from "node:assert/strict"
import { nextId } from "../../app/javascript/easy_flow/canvas/ids.js"
import { toggled } from "../../app/javascript/easy_flow/canvas/choices.js"
import { amended } from "../../app/javascript/easy_flow/canvas/rows.js"

test("names a new step after its type", () => {
  assert.equal(nextId("question", []), "question")
})

test("numbers a new step when its type is taken", () => {
  assert.equal(nextId("question", [ "question" ]), "question_2")
})

test("keeps counting past every name already taken", () => {
  assert.equal(nextId("question", [ "question", "question_2", "question_3" ]), "question_4")
})

test("ignores names belonging to other types", () => {
  assert.equal(nextId("condition", [ "question", "question_2" ]), "condition")
})

test("adds a choice that was not chosen", () => {
  assert.deepEqual(toggled([ "email" ], "sms"), [ "email", "sms" ])
})

test("removes a choice that was chosen", () => {
  assert.deepEqual(toggled([ "email", "sms" ], "email"), [ "sms" ])
})

test("adds to an empty choice list", () => {
  assert.deepEqual(toggled([], "email"), [ "email" ])
})

const rows = [ { value: "low", weight: 1 }, { value: "high", weight: 5 } ]

test("amends the field named in the row given", () => {
  assert.equal(amended(rows, 1, "weight", 9)[1].weight, 9)
})

test("leaves the other rows untouched", () => {
  assert.deepEqual(amended(rows, 1, "weight", 9)[0], { value: "low", weight: 1 })
})

test("leaves the amended row's other fields alone", () => {
  assert.equal(amended(rows, 1, "weight", 9)[1].value, "high")
})

test("does not change the rows it was given", () => {
  amended(rows, 1, "weight", 9)

  assert.equal(rows[1].weight, 5)
})
