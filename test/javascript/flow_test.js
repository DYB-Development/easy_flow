import { test } from "node:test"
import assert from "node:assert/strict"
import { standing } from "../../app/javascript/easy_flow/canvas/flow.js"

test("says a version is the one visitors get", () => {
  assert.equal(standing({ version: 84, published: 84 }), "Version 84 · live")
})

test("says when visitors are still on an older version", () => {
  assert.equal(standing({ version: 90, published: 84 }), "Version 90 · visitors still on 84")
})

test("says when a version has been created but never published", () => {
  assert.equal(standing({ version: 3, published: null }), "Version 3 · never published")
})

test("says when no version has been created", () => {
  assert.equal(standing({ version: null, published: null }), "No version yet")
})
