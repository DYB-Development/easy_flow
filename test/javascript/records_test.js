import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Records from "../../app/javascript/easy_flow/canvas/Records.jsx"

const drawn = () => renderToStaticMarkup(React.createElement(Records, {
  holds: { value: "string" }, labels: { value: "Value" }, rows: [ { value: "high" } ],
  onChange: () => {}, onSettle: () => {}
}))

test("borders each record with keystone's border colors", () => {
  assert.match(drawn(), /^<div[^>]*><div class="rounded-md border border-gray-200 dark:border-zinc-700"/)
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}<`))?.[1] || "").split(" ")

test("writes each record's field names in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "Value").includes("text-gray-500"))
})

test("offers removing a record as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Remove").includes("ks-button-secondary"))
})

test("offers adding a record as keystone's secondary button", () => {
  assert.ok(classesOf(drawn(), "Add").includes("ks-button-secondary"))
})
