import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Canvas, { Choosing } from "../../app/javascript/easy_flow/canvas/Canvas.jsx"

const drawn = (nodes = []) => renderToStaticMarkup(React.createElement(Canvas, {
  base: "/flows/1/canvas", token: "t",
  initial: { nodes, edges: [], violations: [], palette: [], undoable: false, redoable: false, flow: {} }
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
