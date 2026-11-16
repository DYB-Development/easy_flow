import { test } from "node:test"
import assert from "node:assert/strict"
import GroupBox from "../../app/javascript/easy_flow/canvas/GroupBox.jsx"

const box = (overrides = {}) => GroupBox({ id: "loop", bounds: { left: 88, top: 40, width: 264, height: 160 }, onDrop: () => {}, ...overrides })

test("borders a group step's box with a dashed line", () => {
  assert.ok(box().props.className.split(" ").includes("border-dashed"))
})

test("places a group step's box where its header and steps were measured", () => {
  const { left, top, width, height } = box().props.style

  assert.deepEqual({ left, top, width, height }, { left: 88, top: 40, width: 264, height: 160 })
})

test("hands a step dropped on the box to the group step", () => {
  let dropped = false
  box({ onDrop: () => { dropped = true } }).props.onDrop({ preventDefault: () => {} })

  assert.ok(dropped)
})
