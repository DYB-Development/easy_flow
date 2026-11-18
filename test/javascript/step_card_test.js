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

const hidingCodes = { hideStepTypeCodes: true }

test("writes no step type code when the host hides them", () => {
  assert.equal(child(card({ type_name: "Condition" }, hidingCodes), (element) => element.props?.children === "condition"), undefined)
})

test("writes the step type's name in the muted text color when the host hides codes", () => {
  const name = child(card({ type_name: "Condition" }, hidingCodes), (element) => element.props?.children === "Condition")

  assert.ok(classes(name).includes("text-gray-500"))
})

const unnamedQuestion = { id: "question_2", label: "question_2", type: "question", type_name: "Question" }

test("writes no id on the box of a step with no name of its own when the host hides codes", () => {
  assert.equal(child(card(unnamedQuestion, hidingCodes), (element) => element.props?.children === "question_2"), undefined)
})

const everyChild = (element) => [ element.props.children ].flat(Infinity).filter(Boolean)

test("writes the type's name once on the box of a step with no name of its own when the host hides codes", () => {
  assert.equal(everyChild(card(unnamedQuestion, hidingCodes)).filter((element) => element.props?.children === "Question").length, 1)
})

test("heads an end step with no name of its own by its type's name when the host hides codes", () => {
  const end = card({ id: "terminal", label: "terminal", type: "terminal", type_name: "End", ends_here: true }, hidingCodes)

  assert.ok(child(end, (element) => element.props?.children === "End"))
})

test("writes a start card's label in keystone's muted text color", () => {
  const label = child(card({ begins_here: true, label: "Start" }), (element) => element.props?.children === "Start")

  assert.ok(classes(label).includes("text-gray-500"))
})

test("writes the count of the step's problems in red", () => {
  const count = child(card({ violations: [ { problem: "unreachable", detail: null } ] }), (element) => element.props?.children === "1 error")

  assert.ok(classes(count).includes("text-red-600"))
})

test("leaves the sentence of each of the step's problems to the flow's problem list", () => {
  assert.equal(child(card({ violations: [ { problem: "dead_end", detail: null, sentence: "Gate leads nowhere." } ] }), (element) => element.props?.children === "Gate leads nowhere."), undefined)
})

test("marks a step that runs another flow", () => {
  assert.ok(child(card({ starts_a_flow: true }), (element) => element.props?.children === "Runs a flow"))
})

test("shows no picture mark on a step with no picture", () => {
  assert.equal(child(card(), (element) => element.props?.children === "Has a picture"), undefined)
})

test("opens the flow a step runs when its card is clicked", () => {
  let opened = null
  card({ starts_a_flow: true, opens: "/flows/7" }, { onOpen: (path) => { opened = path } }).props.onClick()

  assert.equal(opened, "/flows/7")
})

test("picks a step that runs another flow as a connection's target while connecting", () => {
  let picked = false
  card({ starts_a_flow: true, opens: "/flows/7" }, { connecting: true, onSelect: () => { picked = true }, onOpen: () => {} }).props.onClick()

  assert.ok(picked)
})

test("a Settings button on a step that runs another flow selects the step", () => {
  let selected = false
  const settings = child(card({ starts_a_flow: true, opens: "/flows/7" }, { onSelect: () => { selected = true } }), (element) => element.props?.children === "Settings")

  settings.props.onClick({ stopPropagation: () => {} })

  assert.ok(selected)
})

test("sizes a compact card to what it says rather than to the full card width", () => {
  assert.equal(card({}, { compact: true }).props.style.width, undefined)
})

test("writes a compact card's type above its name", () => {
  const [ first ] = everyChild(card({}, { compact: true }))

  assert.equal(first.props.children, "condition")
})

test("borders a compact card with a thin line", () => {
  assert.ok(classes(card({}, { compact: true })).includes("border"))
})

test("writes the step's summary on the line under its name", () => {
  const lines = everyChild(card({ summary: "copy_writer@prod" })).map((element) => element.props?.children)

  assert.equal(lines[lines.indexOf("Gate") + 1], "copy_writer@prod")
})

test("writes a selected step's summary in the accent color", () => {
  const summary = child(card({ summary: "copy_writer@prod" }, { selected: true }), (element) => element.props?.children === "copy_writer@prod")

  assert.ok(classes(summary).includes("text-accent-600"))
})

test("writes a full-size card's type above its name when the card asks for it", () => {
  const [ first ] = everyChild(card({}, { typeAbove: true }))

  assert.equal(first.props.children, "condition")
})

test("counts a step's problem as one error", () => {
  assert.ok(child(card({ violations: [ { problem: "dead_end", detail: null, sentence: "Gate leads nowhere." } ] }), (element) => element.props?.children === "1 error"))
})

test("counts a step's two problems as two errors", () => {
  const problems = [ { problem: "dead_end", detail: null }, { problem: "unreachable", detail: null } ]

  assert.ok(child(card({ violations: problems }), (element) => element.props?.children === "2 errors"))
})

test("writes a step's error count in place of its summary when the step has problems", () => {
  const lines = everyChild(card({ summary: "copy_writer@prod", violations: [ { problem: "dead_end", detail: null } ] })).map((element) => element.props?.children)

  assert.deepEqual(lines.slice(lines.indexOf("Gate") + 1, lines.indexOf("Gate") + 2).concat(lines.includes("copy_writer@prod")), [ "1 error", false ])
})
