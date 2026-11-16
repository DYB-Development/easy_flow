import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import StepList, { listed } from "../../app/javascript/easy_flow/canvas/StepList.jsx"

const entries = [ { type: "question", label: "Question" }, { type: "condition", label: "Condition" }, { type: "notify", label: "Notify" } ]

const headingsAndTypes = (sections) => sections.map((section) => [ section.heading, section.entries.map((entry) => entry.type) ])

test("lists the step types under the headings their host names, in the host's order", () => {
  assert.deepEqual(headingsAndTypes(listed(entries, { Control: [ "condition" ], Agents: [ "notify", "question" ] }, "")),
                   [ [ "Control", [ "condition" ] ], [ "Agents", [ "notify", "question" ] ] ])
})

test("lists the step types its host put in no group after the groups, under no heading", () => {
  assert.deepEqual(headingsAndTypes(listed(entries, { Control: [ "condition" ] }, "")),
                   [ [ "Control", [ "condition" ] ], [ null, [ "question", "notify" ] ] ])
})

test("lists only the step types whose name holds what was searched for, in any case", () => {
  assert.deepEqual(headingsAndTypes(listed(entries, { Agents: [ "notify", "question" ] }, "TIF")),
                   [ [ "Agents", [ "notify" ] ] ])
})

const drawn = (given = {}) => renderToStaticMarkup(React.createElement(StepList, {
  entries, groups: { Control: [ "condition" ] }, onPick: () => {}, onCarry: () => {}, onDrop: () => {}, ...given
}))

test("opens with keystone's search field for the step types", () => {
  assert.match(drawn(), /<input[^>]*aria-label="Search steps"[^>]*class="ks-input/)
})

const classesOf = (html, text) => (html.match(new RegExp(`<[^<>]*class="([^"]*)"[^<>]*>${text}<`))?.[1] || "").split(" ")

test("writes each group's heading in keystone's muted text color", () => {
  assert.ok(classesOf(drawn(), "Control").includes("text-gray-500"))
})

test("offers each step type as a box bordered in keystone's panel border on the canvas's surface color", () => {
  assert.deepEqual([ "ks-panel", "bg-surface-50" ].filter((name) => classesOf(drawn(), "Condition").includes(name)), [ "ks-panel", "bg-surface-50" ])
})
