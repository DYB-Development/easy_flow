import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Inspector from "../../app/javascript/easy_flow/canvas/Inspector.jsx"

const drawn = (given = {}) => renderToStaticMarkup(React.createElement(Inspector, {
  node: { id: "gate", type: "condition", label: "Gate", config: {} },
  fields: { step: "string" }, holds: {}, labels: { step: "Step" }, recordLabels: {}, choices: {},
  onSave: () => {}, onDelete: () => {}, onClose: () => {}, ...given
}))

test("is drawn as a keystone panel", () => {
  assert.match(drawn(), /^<aside[^>]* class="ks-panel"/)
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}`))?.[1] || "").split(" ")

test("writes the step's id and type in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "gate · condition").includes("text-gray-500"))
})

test("colors the close button with keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "×").includes("text-gray-500"))
})

test("labels each field with keystone's label", () => {
  assert.match(drawn(), /class="ks-label"[^>]*>(<span[^>]*>)?Step</)
})

test("offers deleting the step as keystone's danger button", () => {
  assert.ok(classesOf(drawn(), "Delete step").includes("ks-button-danger"))
})
