import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Drawer from "../../app/javascript/easy_flow/canvas/Drawer.jsx"

const checks = [
  { level: "error", node: "ab_test_created", sentence: "Emit event needs a value for Event." },
  { level: "ok", node: null, sentence: "Every connection joins two steps that exist." }
]

const drawn = (given = {}) => renderToStaticMarkup(React.createElement(Drawer, { checks, tabs: [], onSelect: () => {}, ...given }))

test("draws its tabs as keystone's underlined tabs, set at the start of the row", () => {
  assert.match(drawn(), /class="ks-tab-bar flex flex-wrap justify-start[^"]*ks-tab-bar-underline"/)
})

test("counts the problems after the Validation tab's name", () => {
  assert.match(drawn(), />Validation <span class="ks-tab-count">1<\/span><\/button>/)
})
