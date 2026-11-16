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

const hosted = [ { label: "Fixtures", count: "12/12", content: "<p>12 of 12 pass.</p>" }, { label: "Dry-run", count: null, content: "<p>No dry-run yet.</p>" } ]

test("adds each tab its host gives it, with the host's count after its name", () => {
  assert.match(drawn({ tabs: hosted }), />Fixtures <span class="ks-tab-count">12\/12<\/span><\/button>/)
})

test("writes only the name of a host tab with nothing to count", () => {
  assert.match(drawn({ tabs: hosted }), /<button[^>]*>Dry-run<\/button>/)
})
