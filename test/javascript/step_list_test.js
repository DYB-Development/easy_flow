import { test } from "node:test"
import assert from "node:assert/strict"
import { listed } from "../../app/javascript/easy_flow/canvas/StepList.jsx"

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
