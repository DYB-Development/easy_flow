import { test } from "node:test"
import assert from "node:assert/strict"
import Joint from "../../app/javascript/easy_flow/canvas/Joint.jsx"

const link = { id: "ask-gate-0", source: "ask", target: "gate" }

const everyChild = (element) => [ element.props.children ].flat(Infinity).filter(Boolean)
  .flatMap((each) => (each.props ? [ each, ...everyChild(each) ] : []))

const titled = (element, title) => everyChild(element).find((each) => each.props.title === title)

test("inserts a step on the line's connection when its insert button is used", () => {
  let inserted = null
  titled(Joint({ link, onInsert: (on) => { inserted = on } }), "Insert a step here").props.onClick({})

  assert.equal(inserted, link)
})

test("removes the line's connection when its remove button is used", () => {
  let removed = null
  titled(Joint({ link, onInsert: () => {}, onRemove: (on) => { removed = on } }), "Remove this connection").props.onClick()

  assert.equal(removed, link)
})

test("moves a dragged step onto the line's connection when it is dropped there", () => {
  let moved = null
  Joint({ link, onInsert: () => {}, onRemove: () => {}, onDrop: (on) => { moved = on } }).props.onDrop({ preventDefault: () => {} })

  assert.equal(moved, link)
})

test("keeps the insert button showing for a host that always shows them", () => {
  const insert = titled(Joint({ link, alwaysShowInsertButtons: true, onInsert: () => {}, onRemove: () => {} }), "Insert a step here")

  assert.ok(insert.props.className.split(" ").includes("opacity-100"))
})

test("marks itself as under the pointer when the pointer moves onto the line", () => {
  const line = { dataset: {} }
  Joint({ link, onInsert: () => {}, onRemove: () => {} }).props.onMouseEnter({ currentTarget: line })

  assert.equal(line.dataset.over, "true")
})

test("shows its remove button while the line is marked as under the pointer", () => {
  const remove = titled(Joint({ link, onInsert: () => {}, onRemove: () => {} }), "Remove this connection")

  assert.ok(remove.props.className.split(" ").includes("group-data-[over=true]:opacity-100"))
})
