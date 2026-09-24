import { test } from "node:test"
import assert from "node:assert/strict"
import { offeredTo } from "../../app/javascript/easy_flow/canvas/choices.js"

test("keeps the choices a step type declares for all its steps", () => {
  assert.deepEqual(offeredTo({}, { choices: { tone: [ "warm" ] } }).tone, [ "warm" ])
})

test("prefers the choices computed for this step over its type's", () => {
  const merged = offeredTo({ choices: { step: [ { value: "a" } ] } }, { choices: { step: [] } })

  assert.deepEqual(merged.step, [ { value: "a" } ])
})
