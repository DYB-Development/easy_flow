import { test } from "node:test"
import assert from "node:assert/strict"
import Placeholder from "../../app/javascript/easy_flow/canvas/Placeholder.jsx"

const spot = (dragging) => Placeholder({
  node: { id: "gate-yes", label: "yes" }, dragging, onFill: () => {}, onDrop: () => {}
})

test("colors an empty result spot amber", () => {
  assert.ok(spot(false).props.className?.split(" ").includes("border-amber-500"))
})

test("colors an empty result spot with the accent color while a step is dragged", () => {
  assert.ok(spot(true).props.className.split(" ").includes("border-accent-600"))
})
