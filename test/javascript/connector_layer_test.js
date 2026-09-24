import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import ConnectorLayer from "../../app/javascript/easy_flow/canvas/ConnectorLayer.jsx"

const drawn = () => renderToStaticMarkup(React.createElement(ConnectorLayer, {
  links: [ { id: "a-b", source: "a", target: "b", path: "M 0 0 L 10 10", midX: 5, midY: 5, label: "yes" } ],
  extent: { width: 100, height: 100 }, dragging: null,
  onInsert: () => {}, onRemove: () => {}, onDrop: () => {}
}))

const classesWith = (html, attribute) => (html.match(new RegExp(`<[^<>]*${attribute}[^<>]*`))?.[0].match(/class="([^"]*)"/)?.[1] || "").split(" ")

test("strokes each connection in keystone's line color", () => {
  assert.ok(classesWith(drawn(), 'data-link="a-b"').includes("stroke-gray-400"))
})

test("fills each arrow head in keystone's line color", () => {
  assert.ok(classesWith(drawn(), 'd="M 0 0 L 10 5 L 0 10 z"').includes("fill-gray-400"))
})

test("writes each connection label in keystone's muted text color", () => {
  assert.ok(classesWith(drawn(), 'data-link-label="a-b"').includes("text-gray-500"))
})

test("sets each connection label on the canvas's surface color", () => {
  assert.ok(classesWith(drawn(), 'data-link-label="a-b"').includes("bg-surface-50"))
})
