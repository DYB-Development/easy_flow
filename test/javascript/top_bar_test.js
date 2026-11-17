import { test } from "node:test"
import assert from "node:assert/strict"
import { barPressed } from "../../app/javascript/easy_flow/canvas/topBar.js"

const pressing = (dataset) => {
  const button = { dataset, closest: () => null }
  return { target: { closest: (selector) => (selector === "[data-bar-action]" ? button : null) } }
}

test("sends a top bar button's request to the path the button names", () => {
  const sent = []
  const pressed = barPressed({ send: (...request) => sent.push(request), onPress: () => {} })

  pressed(pressing({ barAction: "archive", barPath: "/archive" }))

  assert.deepEqual(sent, [ [ "/archive", "POST" ] ])
})
