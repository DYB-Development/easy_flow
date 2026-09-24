import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import TypePicker from "../../app/javascript/easy_flow/canvas/TypePicker.jsx"

const drawn = () => renderToStaticMarkup(React.createElement(TypePicker, {
  entries: [ { type: "question", label: "Question" } ], at: { x: 0, y: 0 },
  onPick: () => {}, onConnect: () => {}, onDismiss: () => {}
}))

test("is drawn as a keystone panel", () => {
  assert.match(drawn(), /^<div[^>]* class="ks-panel shadow-lg"/)
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}`))?.[1] || "").split(" ")

test("writes its caption in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "Add a step").includes("text-gray-500"))
})

test("offers each step type as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Question").includes("ks-button-secondary"))
})

test("writes each step type's name in the button's own text color, softened", () => {
  assert.deepEqual(classesOf(drawn(), "question"), [ "opacity-75" ])
})

test("offers connecting to an existing step as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Connect to a step already here").includes("ks-button-secondary"))
})

test("offers cancelling as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Cancel").includes("ks-button-secondary"))
})
