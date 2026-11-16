import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import RunCard from "../../app/javascript/easy_flow/canvas/RunCard.jsx"

const step = { id: "outline", type: "agent", label: "outline", version: "v9", state: "done", status: "8.2s · $0.04" }

const drawn = (node = {}, given = {}) => renderToStaticMarkup(React.createElement(RunCard, { node: { ...step, ...node }, ...given }))

const text = (markup) => markup.replace(/<[^>]+>/g, "|").split("|").filter(Boolean)

test("writes the step's type code, name, version and status line in that order", () => {
  assert.deepEqual(text(drawn()), [ "agent", "outline", "v9", "8.2s · $0.04" ])
})
