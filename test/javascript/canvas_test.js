import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Canvas, { Choosing } from "../../app/javascript/easy_flow/canvas/Canvas.jsx"

const drawn = (nodes = [], palette = []) => renderToStaticMarkup(React.createElement(Canvas, {
  base: "/flows/1/canvas", token: "t",
  initial: { nodes, edges: [], violations: [], palette, undoable: false, redoable: false, flow: {} }
}))

test("writes the editor's text in keystone's text color", () => {
  assert.match(drawn(), /^<div class="text-gray-900 dark:text-gray-100"/)
})

test("sets the canvas on the palette's surface color", () => {
  assert.match(drawn(), /^<div[^>]*><div class="bg-surface-50 dark:bg-surface-950"/)
})

const loose = [ { id: "orphan", label: "Orphan", type: "question", loose: true, ports: [], row: 0, column: 0 } ]

const classesWith = (html, attribute) => (html.match(new RegExp(`<[^<>]*${attribute}[^<>]*`))?.[0].match(/class="([^"]*)"/)?.[1] || "").split(" ")

test("borders the steps not in the flow yet in keystone's border color", () => {
  assert.ok(classesWith(drawn(loose), "data-loose").includes("border-gray-300"))
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}`))?.[1] || "").split(" ")

test("writes the caption above steps not in the flow in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(loose), "Not in the flow yet").includes("text-gray-500"))
})

test("shows the choose-a-step notice in the accent colors", () => {
  const notice = Choosing({ port: "yes", onCancel: () => {} })

  assert.ok(notice.props.className.split(" ").includes("bg-accent-100"))
})

test("colors the notice's cancel link with the accent color", () => {
  const notice = renderToStaticMarkup(React.createElement(Choosing, { port: "yes", onCancel: () => {} }))

  assert.ok(classesOf(notice, "cancel").includes("text-accent-800"))
})

test("draws a step that holds steps as its header line", () => {
  const group = { id: "loop", label: "loop", type: "for_each", config: { list: "outline.variants" }, holds: [], ports: [], row: 0, column: 0 }

  assert.match(drawn([ group ], [ { type: "for_each", fields: { list: "string" } } ]), /data-group-header="loop"[^>]*>for_each · list: outline.variants</)
})

const leftToRight = (nodes, edges = []) => renderToStaticMarkup(React.createElement(Canvas, {
  base: "/flows/1/canvas", token: "t",
  initial: { nodes, edges, violations: [], palette: [], undoable: false, redoable: false, flow: {}, direction: "left_to_right" }
}))

const step = (id, row) => ({ id, label: id, type: "question", config: {}, ports: [], row, column: 0 })

test("draws a left-to-right host's steps side by side in a row", () => {
  assert.match(leftToRight([ step("ask", 0), step("gate", 1) ]), /data-flow-row[^>]*>.*data-step="ask".*data-step="gate"/)
})

test("writes on a left-to-right step's card where each of its branches goes", () => {
  const edges = [ { id: "gate-ask-0", source: "gate", target: "ask", label: "false" } ]

  assert.match(leftToRight([ step("ask", 0), step("gate", 1) ], edges), /data-step="gate".*>false → ask</)
})

test("draws a left-to-right step as a compact card", () => {
  assert.match(leftToRight([ step("ask", 0) ]), /data-step="ask"[^>]*min-width:120px/)
})

test("draws a left-to-right result spot as a compact one", () => {
  const spot = { id: "ask--", label: "next", type: "placeholder", placeholder: true, from: "ask", on: null, config: {}, ports: [], row: 1, column: 0 }

  assert.match(leftToRight([ step("ask", 0), spot ]), /data-placeholder="ask--"[^>]*min-width:120px/)
})

test("lets a left-to-right group step's header line wrap inside its box", () => {
  const group = { id: "loop", label: "loop", type: "for_each", config: {}, holds: [], ports: [], row: 0, column: 0 }

  assert.match(leftToRight([ group ]), /data-group-header="loop"[^>]*white-space:normal/)
})
