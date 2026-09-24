import { test } from "node:test"
import assert from "node:assert/strict"
import StepCard from "../../app/javascript/easy_flow/canvas/StepCard.jsx"

const card = (node = {}, given = {}) => StepCard({
  node: { id: "gate", label: "Gate", type: "condition", violations: [], ports: [], connected: [], ...node },
  selected: false, armed: null, connecting: false,
  onSelect: () => {}, onArm: () => {}, onDragEnd: () => {}, onDragStart: () => {}, ...given
})

const classes = (element) => (element.props.className || "").split(" ")

test("sets the card on keystone's panel background", () => {
  assert.ok(classes(card()).includes("bg-white"))
})

test("borders an ordinary card in keystone's border color", () => {
  assert.ok(classes(card()).includes("border-gray-300"))
})

test("borders a selected card in the accent color", () => {
  assert.ok(classes(card({}, { selected: true })).includes("border-accent-600"))
})

test("borders a card with problems in red", () => {
  assert.ok(classes(card({ violations: [ { problem: "unreachable", detail: null } ] })).includes("border-red-600"))
})

test("borders a card that can be connected to in the accent color", () => {
  assert.ok(classes(card({}, { connecting: true })).includes("border-accent-600"))
})

const child = (element, predicate) => [ element.props.children ].flat(Infinity).filter(Boolean).find(predicate)

test("writes the step's type in keystone's muted text color", () => {
  const type = child(card(), (element) => element.props?.children === "condition")

  assert.ok(classes(type).includes("text-gray-500"))
})

test("writes a start card's label in keystone's muted text color", () => {
  const label = child(card({ begins_here: true, label: "Start" }), (element) => element.props?.children === "Start")

  assert.ok(classes(label).includes("text-gray-500"))
})

test("writes each of the step's problems in red", () => {
  const problem = child(card({ violations: [ { problem: "unreachable", detail: null } ] }), (element) => element.key === "unreachablenull")

  assert.ok(classes(problem).includes("text-red-600"))
})
