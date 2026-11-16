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

test("opens on the Validation tab with one row per check", () => {
  assert.equal(drawn().match(/data-check-row/g)?.length, 2)
})

test("writes each row's level, its step id in monospace, then the check's message", () => {
  assert.match(drawn(), /data-check-row[^>]*><span[^>]*>error<\/span><span class="font-mono">ab_test_created<\/span><span>Emit event needs a value for Event\.<\/span>/)
})

test("shows the content its host gives a tab once that tab is open", () => {
  assert.match(drawn({ tabs: hosted, opened: "Fixtures" }), /<p>12 of 12 pass\.<\/p>/)
})

test("makes a row that names a step a button for that step, and leaves a row with no step plain", () => {
  assert.deepEqual(drawn().match(/<(button|div)[^>]*data-check-row/g).map((tag) => tag.split(" ")[0]), [ "<button", "<div" ])
})
