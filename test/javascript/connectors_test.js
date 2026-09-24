import { test } from "node:test"
import assert from "node:assert/strict"
import { anchor, shy, drawn } from "../../app/javascript/easy_flow/canvas/useConnectors.js"

const frame = { left: 0, top: 0 }
const surface = { scrollLeft: 0, scrollTop: 0 }
const box = { left: 100, top: 50, width: 200, height: 40 }

test("anchors the left side halfway down the card", () => {
  assert.deepEqual(anchor(box, "left", frame, surface), { x: 100, y: 70 })
})

test("anchors the right side halfway down the card", () => {
  assert.deepEqual(anchor(box, "right", frame, surface), { x: 300, y: 70 })
})

test("anchors the top side halfway across the card", () => {
  assert.deepEqual(anchor(box, "top", frame, surface), { x: 200, y: 50 })
})

test("anchors the bottom side halfway across the card", () => {
  assert.deepEqual(anchor(box, "bottom", frame, surface), { x: 200, y: 90 })
})

test("counts the surface's scroll into the anchor", () => {
  assert.deepEqual(anchor(box, "top", frame, { scrollLeft: 10, scrollTop: 25 }), { x: 210, y: 75 })
})

test("holds an arrow short of the top edge", () => {
  assert.deepEqual(shy({ x: 5, y: 5 }, "top"), { x: 5, y: 2 })
})

test("holds an arrow short of the bottom edge", () => {
  assert.deepEqual(shy({ x: 5, y: 5 }, "bottom"), { x: 5, y: 8 })
})

test("holds an arrow short of the left edge", () => {
  assert.deepEqual(shy({ x: 5, y: 5 }, "left"), { x: 2, y: 5 })
})

test("holds an arrow short of the right edge", () => {
  assert.deepEqual(shy({ x: 5, y: 5 }, "right"), { x: 8, y: 5 })
})

const a = { x: 10, y: 20 }
const b = { x: 60, y: 120 }

test("draws a straight route as one line", () => {
  assert.equal(drawn({ route: "straight" }, a, b, 70, 0).path, "M 10 20 L 60 120")
})

test("draws a turn route across then down", () => {
  assert.equal(drawn({ route: "turn" }, a, b, 70, 0).path, "M 10 20 H 60 V 120")
})

test("draws a lane route down to the lane, across, then down", () => {
  assert.equal(drawn({ route: "lane" }, a, b, 70, 0).path, "M 10 20 V 70 H 60 V 120")
})

test("draws a detour route out around the cards", () => {
  assert.equal(drawn({ route: "detour" }, a, b, 70, 88).path, "M 10 20 H 88 V 120 H 60")
})

test("puts a straight route's controls midway between its ends", () => {
  const link = drawn({ route: "straight" }, a, b, 70, 88)
  assert.deepEqual([ link.midX, link.midY ], [ 35, 70 ])
})

test("puts a lane route's controls on the lane", () => {
  assert.equal(drawn({ route: "lane" }, a, b, 70, 88).midY, 70)
})

test("puts a detour route's controls out on the detour", () => {
  assert.equal(drawn({ route: "detour" }, a, b, 70, 88).midX, 88)
})
